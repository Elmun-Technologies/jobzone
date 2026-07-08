-- 0048_applicant_job_status.sql
-- An applicant's own applications list must never lose a row when the job is
-- later closed — that's exactly when an applicant most needs their record
-- (e.g. they were hired for the now-filled position). `jobs` RLS exposes only
-- status='open' to non-owners, so the applications list's job embed silently
-- resolved to null for a closed job and the row was dropped.
--
-- Narrow, bounded fix: a definer view exposing just the fields the
-- applications list needs (title, status, company name), scoped to jobs the
-- CALLER has applied to. Mirrors 0027's applicant_locations / 0047's
-- applicant_profiles pattern exactly. Deliberately does NOT grant general
-- `jobs` read access — job_feed (security_invoker=true) and the job-detail
-- page are untouched, so a closed job still 404s there (that page has no
-- closed-job UI at all; widening its visibility is a separate feature).

create or replace view public.my_applied_jobs as
  select distinct j.id, j.title, j.status, c.name as company_name
  from public.jobs j
  join public.companies c on c.id = j.company_id
  where exists (
    select 1 from public.applications a
    where a.job_id = j.id and a.applicant_id = auth.uid()
  );

revoke all on public.my_applied_jobs from anon;
grant select on public.my_applied_jobs to authenticated;
