-- 0049_resume_subtables_lockdown.sql
-- Close a pre-existing PII gap the new employer résumé feature (0047) is the
-- first thing to actively surface and depend on: `experiences`, `educations`,
-- `certifications`, and `profile_skills` have been `selectable by authenticated
-- using (true)` since 0001 — any signed-in user can read anyone's full work
-- history / education by profile_id, not just the profile's owner or an
-- employer with a real relationship to that candidate.
--
-- Verified no legitimate cross-user read relies on the open policy: every
-- existing read site (mobile cv_repository.dart / profile_repository.dart, web
-- resume.ts) is already scoped to the caller's own profile_id. The only
-- cross-user reader is applicant-resume.ts (0047's employer résumé page),
-- which only ever needs an applicant who applied to the caller's job.
--
-- Idempotent (drop policy if exists / create or replace), mirrors the
-- is_job_owner helper pattern (0003).

create or replace function public.is_recruiter_of(p_profile_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.applications a
    where a.applicant_id = p_profile_id and public.is_job_owner(a.job_id)
  );
$$;

do $$
declare t text;
begin
  foreach t in array array[
    'experiences','educations','certifications','profile_skills'
  ] loop
    execute format('drop policy if exists "%1$s selectable by authenticated" on public.%1$I;', t);
    execute format('drop policy if exists "%1$s select own or recruiter" on public.%1$I;', t);
    execute format($f$create policy "%1$s select own or recruiter" on public.%1$I
                       for select to authenticated
                       using (auth.uid() = profile_id or public.is_recruiter_of(profile_id));$f$, t);
  end loop;
end $$;
