-- 0080_my_bookmarked_jobs.sql
-- A saved vacancy that gets closed must not vanish from "Saved" without a word.
--
-- Saved jobs are resolved through `job_feed`, whose RLS exposes only
-- status='open' to non-owners. So when an employer closes a vacancy, it stops
-- coming back and the row simply disappears from the seeker's saved list —
-- while the `bookmarks` row is still sitting in the database. The seeker saved
-- something to come back to and it is gone with no explanation; from their
-- side it is indistinguishable from the app having lost it, or from never
-- having saved it at all.
--
-- 0048 already solved this shape for applications, and this is its twin:
-- a definer view exposing just what the saved list renders (title, status,
-- company name), scoped to jobs the CALLER has bookmarked. The clients show
-- the closed ones with a marker instead of dropping them, the same way the
-- applications list has since 0048.
--
-- Deliberately NOT general `jobs` read access. job_feed (security_invoker) and
-- the job-detail page are untouched: a closed vacancy still 404s there, which
-- is why the saved list links to it only while it is open.

create or replace view public.my_bookmarked_jobs as
  select distinct j.id, j.title, j.status, c.name as company_name
  from public.jobs j
  join public.companies c on c.id = j.company_id
  where exists (
    select 1 from public.bookmarks b
    where b.job_id = j.id and b.profile_id = auth.uid()
  );

revoke all on public.my_bookmarked_jobs from anon;
grant select on public.my_bookmarked_jobs to authenticated;
