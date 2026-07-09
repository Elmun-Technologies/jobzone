-- 0050_recommended_candidates.sql
-- "When an employer posts a job, recommend matching workers from the résumé
-- pool; the employer can invite the ones they like or ignore the rest."
--
-- Two SECURITY DEFINER functions, both gated to the job owner (is_job_owner):
--   * recommended_candidates(job) — ranks open-to-work seekers against the job
--     and returns ONLY safe card fields (the same columns profiles_public
--     already exposes) plus a score + match signals. No PII (phone/email/
--     lat/lng/bio/pay) ever leaves the function, so this doesn't widen the
--     0027/0049 lockdown — the résumé sub-tables are read only to COMPUTE the
--     score, never returned.
--   * invite_candidate(job, candidate) — lets the owner nudge a recommended
--     candidate: inserts a job-linked notification (type 'job_match', which
--     both clients already deep-link to the vacancy — no renderer change), so
--     the candidate learns about the job and can apply. Idempotent per (job,
--     candidate).

create index if not exists idx_profiles_seeker_open
  on public.profiles (role, is_open_to_work);

create or replace function public.recommended_candidates(p_job_id uuid)
returns table (
  id uuid,
  full_name text,
  headline text,
  avatar_url text,
  city text,
  worker_verified boolean,
  availability text,
  score int,
  same_city boolean,
  role_match boolean,
  skills_matched int
)
language sql stable security definer set search_path = public as $$
  with job as (
    select j.id, j.title, j.city, j.skills_required
    from public.jobs j
    where j.id = p_job_id and public.is_job_owner(j.id)   -- owner gate
  ),
  pool as (
    select
      p.id, p.full_name, p.headline, p.avatar_url, p.city,
      (p.worker_verified_at is not null) as worker_verified,
      p.availability,
      (job.city is not null and p.city is not null
        and lower(trim(p.city)) = lower(trim(job.city))) as same_city,
      -- Same-language role signal: the seeker's headline appears in the job
      -- title (e.g. headline "Quruvchi" in title "Quruvchi kerak").
      (length(coalesce(trim(p.headline), '')) >= 3
        and job.title ilike '%' || trim(p.headline) || '%') as headline_match,
      exists (
        select 1 from public.experiences e
        where e.profile_id = p.id
          and length(coalesce(trim(e.title), '')) >= 3
          and job.title ilike '%' || trim(e.title) || '%'
      ) as exp_match,
      (
        select count(*) from public.profile_skills ps
        join public.skills s on s.id = ps.skill_id
        where ps.profile_id = p.id
          and exists (
            select 1 from unnest(job.skills_required) req
            where lower(trim(req)) = lower(trim(s.name))
          )
      )::int as skills_matched
    from public.profiles p, job
    where p.role = 'job_seeker'
      and p.is_open_to_work = true
      and not exists (
        select 1 from public.applications a
        where a.job_id = job.id and a.applicant_id = p.id
      )
  ),
  scored as (
    select *,
      ( (case when same_city then 3 else 0 end)
      + (case when headline_match then 3 else 0 end)
      + (case when exp_match then 2 else 0 end)
      + least(skills_matched, 3) ) as score
    from pool
  )
  select id, full_name, headline, avatar_url, city, worker_verified, availability,
         score, same_city, (headline_match or exp_match) as role_match,
         skills_matched
  from scored
  where score > 0
  order by score desc, worker_verified desc, full_name
  limit 24;
$$;

revoke all on function public.recommended_candidates(uuid) from anon;
grant execute on function public.recommended_candidates(uuid) to authenticated;

create or replace function public.invite_candidate(p_job_id uuid, p_candidate uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_title text;
  v_company text;
begin
  if not public.is_job_owner(p_job_id) then
    raise exception 'not authorized';
  end if;

  select j.title, c.name into v_title, v_company
  from public.jobs j
  join public.companies c on c.id = j.company_id
  where j.id = p_job_id;
  if v_title is null then
    raise exception 'job not found';
  end if;

  -- Don't re-notify: one invitation per (job, candidate).
  if exists (
    select 1 from public.notifications n
    where n.recipient_id = p_candidate
      and n.type = 'job_match'
      and n.data->>'job_id' = p_job_id::text
      and n.data->>'invited' = 'true'
  ) then
    return;
  end if;

  insert into public.notifications (recipient_id, type, title, body, data)
  values (
    p_candidate, 'job_match',
    'Ish taklifi',
    v_company || ' sizni "' || v_title || '" lavozimiga taklif qilmoqda.',
    jsonb_build_object('job_id', p_job_id, 'invited', true)
  );
end;
$$;

revoke all on function public.invite_candidate(uuid, uuid) from anon;
grant execute on function public.invite_candidate(uuid, uuid) to authenticated;
