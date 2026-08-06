-- 0075_applicant_resume_scoped_rpc.sql
-- Close a bulk-scrape side channel in the employer résumé feature (0047/0049).
--
-- 0049 gave `experiences`/`educations`/`certifications`/`profile_skills` a
-- "select own or recruiter" policy: `auth.uid() = profile_id or
-- is_recruiter_of(profile_id)`. RLS row policies can only filter which ROWS a
-- query sees, not the SHAPE of the query — so that policy, while row-correct,
-- also authorizes a completely unfiltered `GET /rest/v1/experiences` (no
-- `profile_id` filter at all) for any signed-in recruiter, returning every
-- row where `is_recruiter_of(profile_id)` is true in one response, paginated
-- via standard Range headers. `applicant_profiles` (0047) grants the same
-- shape of access for the profile-level résumé fields.
--
-- Concretely: a free account can post one vacancy (no pre-publish moderation
-- is intentional — see CLAUDE.md), let real seekers apply, then issue a
-- handful of unfiltered REST calls and walk away with the full CV — work
-- history, education, certifications, skills, summary, languages, expected
-- pay — of every applicant, instead of the one-applicant-at-a-time access the
-- product actually grants through the UI. `applicant-resume.ts` (the only
-- legitimate cross-user reader — verified by 0049) has only ever queried one
-- `profile_id` at a time; nothing in either app needs the bulk shape.
--
-- Fix: revoke the recruiter arm of "select own or recruiter" back to
-- owner-only, and revoke the `applicant_profiles` grant, replacing both with
-- one SECURITY DEFINER RPC that takes a single applicant id, re-checks
-- `is_recruiter_of` itself, and returns everything `getApplicantResume()`
-- needs in one jsonb payload. A caller can still only ever ask about one
-- applicant per call — there is no way to omit the id and get "the rest".
--
-- Mobile does not read any of these four objects for the applicant view (it
-- shows headline/skills/cover-letter/screening-answers from `applications` +
-- `profiles_public`, confirmed against applicants_repository.dart) so this is
-- web-only in effect, even though the grant change applies at the DB level.

-- 1. Base tables: owner-only. Recruiters now reach these ONLY through the RPC.
do $$
declare t text;
begin
  foreach t in array array[
    'experiences','educations','certifications','profile_skills'
  ] loop
    execute format('drop policy if exists "%1$s select own or recruiter" on public.%1$I;', t);
    execute format($f$create policy "%1$s select own" on public.%1$I
                       for select to authenticated
                       using (auth.uid() = profile_id);$f$, t);
  end loop;
end $$;

-- 2. applicant_profiles view: no longer directly queryable by clients. Left in
-- place (the RPC below selects from it internally) rather than dropped, since
-- dropping+recreating a view requires restating its exact column order and
-- nothing else in this migration needs to.
revoke select on public.applicant_profiles from authenticated;

-- 3. The single-applicant, SECURITY DEFINER replacement. Re-checks
-- is_recruiter_of() itself rather than depending on caller RLS, so it stays
-- correct even though it runs with the function owner's privileges.
create or replace function public.get_applicant_resume(p_applicant_id uuid)
returns jsonb language plpgsql security definer set search_path = public stable as $$
declare
  v_result jsonb;
begin
  if p_applicant_id is null or not public.is_recruiter_of(p_applicant_id) then
    return null;
  end if;

  select jsonb_build_object(
    'summary', ap.summary,
    'summary_ai_generated', ap.summary_ai_generated,
    'languages', ap.languages,
    'experience_level', ap.experience_level,
    'desired_pay_min', ap.desired_pay_min,
    'desired_pay_currency', ap.desired_pay_currency,
    'experiences', coalesce((
      select jsonb_agg(jsonb_build_object(
        'title', e.title,
        'company_name', e.company_name,
        'start_date', e.start_date,
        'end_date', e.end_date,
        'is_current', e.is_current,
        'description', e.description
      ) order by e.end_date desc nulls first)
      from public.experiences e where e.profile_id = p_applicant_id
    ), '[]'::jsonb),
    'educations', coalesce((
      select jsonb_agg(jsonb_build_object(
        'school', ed.school,
        'degree', ed.degree,
        'field', ed.field,
        'start_date', ed.start_date,
        'end_date', ed.end_date,
        'is_current', ed.is_current
      ) order by ed.end_date desc nulls first)
      from public.educations ed where ed.profile_id = p_applicant_id
    ), '[]'::jsonb),
    'certificates', coalesce((
      select jsonb_agg(jsonb_build_object(
        'name', c.name,
        'issuer', c.issuer,
        'issued_date', c.issued_date,
        'expiry_date', c.expiry_date
      ) order by c.issued_date desc nulls last)
      from public.certifications c where c.profile_id = p_applicant_id
    ), '[]'::jsonb),
    'skills', coalesce((
      select jsonb_agg(s.name)
      from public.profile_skills ps
      join public.skills s on s.id = ps.skill_id
      where ps.profile_id = p_applicant_id
    ), '[]'::jsonb)
  )
  into v_result
  from public.applicant_profiles ap
  where ap.applicant_id = p_applicant_id;

  -- applicant_profiles is `distinct ... where is_job_owner(a.job_id)`, so a
  -- caller who owns the job but whose applicant row predates it (shouldn't
  -- happen, but the view could still miss a row if `profiles` lacks one) gets
  -- an empty-but-authorized payload rather than null, mirroring EMPTY on the
  -- TS side.
  if v_result is null then
    v_result := jsonb_build_object(
      'summary', null, 'summary_ai_generated', false, 'languages', '{}'::jsonb,
      'experience_level', null, 'desired_pay_min', null, 'desired_pay_currency', null,
      'experiences', '[]'::jsonb, 'educations', '[]'::jsonb,
      'certificates', '[]'::jsonb, 'skills', '[]'::jsonb
    );
  end if;

  return v_result;
end;
$$;

grant execute on function public.get_applicant_resume(uuid) to authenticated;
