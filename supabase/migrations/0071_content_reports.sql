-- 0071_content_reports.sql
-- User-content report queue — required by Apple 1.2 (UGC apps must let
-- users flag objectionable content and let moderators action reports in
-- 24 hours) and generally aligned with Play Store UGC guidance.
--
-- Any signed-in user can report a job posting or company; each report is
-- one row in `content_reports`. The admin panel exposes the queue via a
-- new `/admin/reports` page (see admin definer RPC below).
--
-- Reason is a fixed enum so the queue is groupable. `details` is
-- free-text (500-char cap enforced client-side + varchar limit here).

create table if not exists public.content_reports (
  id           bigint generated always as identity primary key,
  reporter_id  uuid references public.profiles(id) on delete set null,
  target_type  text not null check (target_type in ('job', 'company', 'review')),
  target_id    uuid not null,
  reason       text not null check (reason in (
    'spam', 'scam', 'misleading', 'discrimination', 'illegal',
    'inappropriate', 'personal_info', 'other'
  )),
  details      varchar(500),
  status       text not null default 'open'
    check (status in ('open', 'reviewed', 'dismissed', 'action_taken')),
  admin_note   text,
  resolved_at  timestamptz,
  resolved_by  uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now()
);

create index if not exists content_reports_status_idx
  on public.content_reports (status, created_at desc);
create index if not exists content_reports_target_idx
  on public.content_reports (target_type, target_id);
create index if not exists content_reports_reporter_idx
  on public.content_reports (reporter_id);

alter table public.content_reports enable row level security;

-- Users see the reports they filed (transparency + duplicate-prevention).
drop policy if exists "own reports readable" on public.content_reports;
create policy "own reports readable"
  on public.content_reports for select to authenticated
  using (reporter_id = auth.uid());

-- Admins see everything.
drop policy if exists "admins see all reports" on public.content_reports;
create policy "admins see all reports"
  on public.content_reports for select to authenticated
  using (public.is_admin());

-- Users file their own reports; no update/delete client-side.
drop policy if exists "users file own reports" on public.content_reports;
create policy "users file own reports"
  on public.content_reports for insert to authenticated
  with check (reporter_id = auth.uid());

-- Admin resolves. Update-only via admin RPC below (no direct update
-- policy) so every state change flows through admin_audit().
-- No update/delete policies on purpose.

-- ---------------------------------------------------------------------------
-- Admin RPCs
-- ---------------------------------------------------------------------------

-- Resolve a report. status transitions: open → reviewed | dismissed |
-- action_taken. Audit trail via admin_audit().
create or replace function public.admin_resolve_report(
  p_report bigint,
  p_status text,
  p_note text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_status not in ('reviewed', 'dismissed', 'action_taken') then
    raise exception 'invalid status';
  end if;
  update public.content_reports
     set status      = p_status,
         admin_note  = coalesce(p_note, admin_note),
         resolved_by = auth.uid(),
         resolved_at = now()
   where id = p_report;
  if not found then raise exception 'report not found'; end if;

  perform public.admin_audit(
    'report.' || p_status,
    'content_report',
    p_report::text,
    coalesce(jsonb_build_object('note', p_note), '{}'::jsonb)
  );
end;
$$;
revoke all on function public.admin_resolve_report(bigint, text, text) from public;
grant execute on function public.admin_resolve_report(bigint, text, text) to authenticated;
