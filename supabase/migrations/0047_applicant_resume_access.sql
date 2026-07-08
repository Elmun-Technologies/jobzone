-- 0047_applicant_resume_access.sql
-- Employer-facing applicant résumé.
--
-- Seekers fill in a rich résumé (an "About me" summary, languages, experience
-- level, expected pay), but after the 0027 PII lockdown `profiles` is owner-only
-- (`auth.uid() = id`), so a recruiter can't read those fields — even for a
-- candidate who applied to their own job, i.e. exactly the person the résumé is
-- meant for. This exposes the profile-level résumé fields, and ONLY them, ONLY
-- to an employer the candidate applied to.
--
-- Mirrors 0027's `applicant_locations` gating: a (definer) view whose
-- `is_job_owner` predicate is evaluated with the CALLER's auth.uid(), so there
-- is no cross-tenant leakage. The résumé sub-tables (experiences, educations,
-- certifications, profile_skills) are already `selectable by authenticated`
-- (0001), so the app reads those directly.

create or replace view public.applicant_profiles as
  select distinct
    a.applicant_id,
    p.summary,
    p.summary_ai_generated,
    p.languages,
    p.experience_level,
    p.desired_pay_min,
    p.desired_pay_currency
  from public.applications a
  join public.profiles p on p.id = a.applicant_id
  where public.is_job_owner(a.job_id);

revoke all on public.applicant_profiles from anon;
grant select on public.applicant_profiles to authenticated;
