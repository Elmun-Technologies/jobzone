-- 0062_security_hardening.sql
-- Two production PII/moderation leaks found in the go-live audit. Both are
-- read-side RLS gaps on base tables (the shipping clients read the safe views,
-- but the REST API exposes the base tables directly).
--
-- Idempotent (drop policy if exists / create or replace). Safe to re-run.

-- 1) CV sub-tables still world-readable to any authenticated user ------------
-- 0049 locked experiences/educations/certifications/profile_skills to
-- owner-or-recruiter but MISSED projects, volunteer_experiences and awards —
-- the 0001 `"<t> selectable by authenticated" using (true)` policy is still
-- live on them, so any signed-in account can read anyone's projects, volunteer
-- history and awards by profile_id. Extend the exact same 0049 policy to them.
do $$
declare t text;
begin
  foreach t in array array[
    'projects','volunteer_experiences','awards'
  ] loop
    execute format('drop policy if exists "%1$s selectable by authenticated" on public.%1$I;', t);
    execute format('drop policy if exists "%1$s select own or recruiter" on public.%1$I;', t);
    execute format($f$create policy "%1$s select own or recruiter" on public.%1$I
                       for select to authenticated
                       using (auth.uid() = profile_id or public.is_recruiter_of(profile_id));$f$, t);
  end loop;
end $$;

-- 2) Blocked jobs / companies still readable via the base tables -------------
-- Moderation (0039) sets blocked_at but does NOT change jobs.status, and the
-- base SELECT policies are `status='open'` (jobs) and `true` (companies), open
-- to anon. job_feed filters blocked rows, but /rest/v1/jobs and
-- /rest/v1/companies still return them (incl. blocked_reason). Add the
-- `blocked_at is null` guard to the public read policies. Owners keep full
-- access via their own for-all policy ("jobs full access for poster" /
-- "companies write owner"); admins read through the service-role key.
drop policy if exists "jobs open readable by all" on public.jobs;
create policy "jobs open readable by all"
  on public.jobs for select
  using (status = 'open' and blocked_at is null);

drop policy if exists "companies readable by all" on public.companies;
create policy "companies readable by all"
  on public.companies for select
  using (blocked_at is null);
