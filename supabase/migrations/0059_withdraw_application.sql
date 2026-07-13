-- 0059_withdraw_application.sql
-- P1 audit fix: "Withdraw Application" was a UI stub. 0027 locked
-- `applications` UPDATE and `application_status_history` INSERT to the job
-- owner only (closing the self-promotion-to-hired hole), which also removed
-- the applicant's own ability to withdraw. This RPC restores just that one
-- self-service transition, security-definer so it can bypass the owner-only
-- policies while still checking the caller owns the application.

alter table public.applications drop constraint if exists applications_current_status_check;
alter table public.applications
  add constraint applications_current_status_check
  check (current_status in ('submitted','viewed','shortlisted','interview','offer','rejected','hired','withdrawn'));

alter table public.application_status_history drop constraint if exists application_status_history_status_check;
alter table public.application_status_history
  add constraint application_status_history_status_check
  check (status in ('submitted','viewed','shortlisted','interview','offer','rejected','hired','withdrawn'));

create or replace function public.withdraw_application(p_application_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_status text;
begin
  if auth.uid() is null then raise exception 'auth required'; end if;

  select current_status into v_status
    from public.applications
    where id = p_application_id and applicant_id = auth.uid()
    for update;
  if v_status is null then raise exception 'application not found'; end if;
  if v_status = 'withdrawn' then return; end if;

  update public.applications set current_status = 'withdrawn' where id = p_application_id;
  insert into public.application_status_history (application_id, status, changed_by)
    values (p_application_id, 'withdrawn', auth.uid());
end;
$$;
grant execute on function public.withdraw_application(uuid) to authenticated;
