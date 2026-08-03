-- 0078_notify_applicants_on_close.sql
-- Tell the people who applied when a vacancy stops taking applications.
--
-- Closing a vacancy is a plain column write — `update jobs set status='closed'`
-- from the web action and from the mobile repository alike. Nothing else
-- happens. The applications keep whatever status they had, and the applicants
-- are told nothing at all: someone who applied a week ago and is sitting at
-- 'submitted' waits for a decision that is never coming, because the listing
-- they applied to no longer exists as far as the product is concerned.
--
-- This notifies them. It deliberately does NOT change their application status.
-- Auto-rejecting would be irreversible and would rewrite the employer's own
-- pipeline records, and "closed" does not mean "you were turned down" — an
-- employer who closes because they hired someone and one who closes because
-- the role was cancelled both press the same button. What the applicant is
-- owed here is the news, not a verdict.
--
-- A trigger rather than client code: both clients close vacancies, and
-- publish_due_jobs()/expiry may in future too. One row inserted here reaches
-- the in-app list, Telegram and push through the 0026 dispatch chain, so this
-- is the only place the rule has to exist.

create or replace function public.notify_applicants_job_closed()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- Only the open → not-open transition, and only once: re-closing an already
  -- closed vacancy, or any other column changing, must not notify again.
  if old.status = 'open' and new.status is distinct from 'open' then
    insert into public.notifications (recipient_id, type, title, body, data)
    select
      a.applicant_id,
      'application_update',
      'Vakansiya yopildi',
      new.title,
      -- `event` is what lets the clients write this sentence in the reader's
      -- own language instead of echoing the two lines above; `application_id`
      -- keeps the row deep-linking to the application, like every other
      -- application_update.
      jsonb_build_object(
        'application_id', a.id,
        'job_id', new.id,
        'event', 'job_closed'
      )
    from public.applications a
    where a.job_id = new.id
      -- Someone already hired, rejected or withdrawn has had their answer;
      -- this is for the ones still waiting.
      and a.current_status in ('submitted', 'viewed', 'shortlisted', 'interview', 'offer');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_applicants_job_closed on public.jobs;
create trigger trg_notify_applicants_job_closed
  after update of status on public.jobs
  for each row execute function public.notify_applicants_job_closed();
