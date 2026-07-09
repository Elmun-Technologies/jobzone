-- 0051_recommended_jobs.sql
-- The seeker-side mirror of 0050: when a job seeker fills in their résumé, show
-- them the open jobs that match it. ONE shared algorithm so web and mobile rank
-- identically — both clients just call this RPC and render the returned rows
-- with their existing job_feed → Job mapper.
--
-- Symmetric with recommended_candidates: score each OPEN job (from job_feed, so
-- expiry + open-status are already enforced there) against the caller's own
-- résumé — same city (+3), same-language role match on headline / past-job
-- title appearing in the vacancy title (+3 / +2), and skills overlap
-- (their skills vs the job's skills_required, +1 each capped at +3) — excluding
-- jobs they already applied to.
--
-- Plain STABLE (security invoker): it only reads the caller's OWN profile /
-- experiences / skills (owner RLS, incl. the 0049 lockdown) and public open
-- jobs, so no elevated privilege is needed. A caller with no profile (or a
-- guest) simply gets no rows.

create or replace function public.recommended_jobs()
returns setof public.job_feed
language sql stable
set search_path = public as $$
  with me as (
    select p.id as uid, p.city, p.headline
    from public.profiles p
    where p.id = auth.uid()
  )
  select jf.*
  from public.job_feed jf
  cross join me
  cross join lateral (
    select (
        (case when (jf.city is not null and me.city is not null
                    and lower(trim(jf.city)) = lower(trim(me.city)))
              then 3 else 0 end)
      + (case when (length(coalesce(trim(me.headline), '')) >= 3
                    and jf.title ilike '%' || trim(me.headline) || '%')
              then 3 else 0 end)
      + (case when exists (
            select 1 from public.experiences e
            where e.profile_id = me.uid
              and length(coalesce(trim(e.title), '')) >= 3
              and jf.title ilike '%' || trim(e.title) || '%'
          ) then 2 else 0 end)
      + least((
            select count(*) from public.profile_skills ps
            join public.skills s on s.id = ps.skill_id
            where ps.profile_id = me.uid
              and exists (
                select 1 from unnest(jf.skills_required) req
                where lower(trim(req)) = lower(trim(s.name))
              )
          )::int, 3)
    ) as score
  ) sc
  where jf.status = 'open'
    and sc.score > 0
    and not exists (
      select 1 from public.applications a
      where a.job_id = jf.id and a.applicant_id = me.uid
    )
  order by sc.score desc, jf.boost_active desc, jf.posted_at desc nulls last
  limit 30;
$$;

revoke all on function public.recommended_jobs() from anon;
grant execute on function public.recommended_jobs() to authenticated;
