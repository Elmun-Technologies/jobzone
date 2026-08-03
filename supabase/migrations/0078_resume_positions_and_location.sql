-- 0078_resume_positions_and_location.sql
-- Seeker résumé, two fields the local job apps have and we did not:
--
--   1. Up to THREE desired positions instead of one headline. A blue-collar
--      seeker is rarely one job title — "Sotuvchi" is also "Kassir" and
--      "Sotuvchi-konsultant" — and with one headline they only ever matched
--      one third of the vacancies they can actually do.
--   2. A canonical desired region/district instead of free text. `jobs` has
--      carried `region`/`district` since 0029 (the mobile employer form writes
--      them), while the résumé only ever had a typed `city`. The matching RPCs
--      compare those with `lower(trim(...)) = lower(trim(...))`, so "Ташкент",
--      "Toshkent" and "toshkent shahri" were three different places.
--
-- `headline` stays authoritative for everything that renders a single title
-- (cards, chat, applicant lists) and keeps being written by both clients —
-- desired_positions is additive, and position #1 is the headline.

alter table public.profiles
  add column if not exists desired_positions text[],
  add column if not exists desired_region    text,
  add column if not exists desired_district  text;

-- Everyone who already has a headline starts with it as their first desired
-- position, so existing résumés gain the new matching without re-editing.
update public.profiles
   set desired_positions = array[trim(headline)]
 where desired_positions is null
   and length(coalesce(trim(headline), '')) >= 2;

-- The wizard caps the list at three; this is the DB's own guard against a
-- client (or a future importer) writing twenty.
alter table public.profiles
  drop constraint if exists profiles_desired_positions_len;
alter table public.profiles
  add constraint profiles_desired_positions_len
    check (
      desired_positions is null
      or coalesce(array_length(desired_positions, 1), 0) <= 3
    );

-- ---------------------------------------------------------------------------
-- Shared matching helpers. Both RPCs below score the same two signals, so they
-- live in one place — the seeker and employer sides must never drift.
-- ---------------------------------------------------------------------------

-- Place names, reduced to something two sides can actually compare.
--
-- One side is now a canonical list value ("Toshkent shahri", "Sergeli"); the
-- other is still whatever the web employer form's city field was typed as
-- ("Toshkent", "toshkent sh."). Straight equality would score those zero and
-- make the matching WORSE than the free-text version it replaces, so drop the
-- administrative suffix and the apostrophe glyphs (Farg'ona / Fargʻona /
-- Fargona) before comparing. Returns null for blank input, so a missing value
-- never compares equal to another missing one.
create or replace function public.loc_norm(p text)
returns text
language sql immutable set search_path = public as $$
  select nullif(
    btrim(
      regexp_replace(
        translate(lower(btrim(coalesce(p, ''))), '''`ʻʼʹ‘’', ''),
        '\s+(shahri|shahar|sh\.|viloyati|viloyat|tumani|tuman|rayoni|rayon|district|city)$',
        ''
      )
    ),
    ''
  );
$$;

-- Location score for a (job, seeker) pair, best signal wins — never summed, or
-- a district match would also collect the region and city points:
--   3  same district, or the job's free-text city names the seeker's district
--   3  same city (legacy signal: web-posted jobs still carry only a city)
--   2  same region, or the job's free-text city names the seeker's region
--   0  otherwise
create or replace function public.location_match_score(
  p_job_region   text,
  p_job_district text,
  p_job_city     text,
  p_region       text,
  p_district     text,
  p_city         text
) returns int
language sql immutable set search_path = public as $$
  select case
    when public.loc_norm(p_district) is not null
         and public.loc_norm(p_district) in (
           public.loc_norm(p_job_district), public.loc_norm(p_job_city)
         ) then 3
    when public.loc_norm(p_city) is not null
         and public.loc_norm(p_city) in (
           public.loc_norm(p_job_city), public.loc_norm(p_job_district)
         ) then 3
    when public.loc_norm(p_region) is not null
         and public.loc_norm(p_region) in (
           public.loc_norm(p_job_region), public.loc_norm(p_job_city)
         ) then 2
    else 0
  end;
$$;

-- True when any of the seeker's desired positions (or their headline) appears
-- in the vacancy title — the same "same-language role match" idea as before,
-- just over the whole list instead of a single string.
create or replace function public.title_matches_positions(
  p_title     text,
  p_headline  text,
  p_positions text[]
) returns boolean
language sql immutable set search_path = public as $$
  select
    (
      length(coalesce(trim(p_headline), '')) >= 3
      and p_title ilike '%' || trim(p_headline) || '%'
    )
    or exists (
      select 1 from unnest(coalesce(p_positions, '{}'::text[])) pos
      where length(coalesce(trim(pos), '')) >= 3
        and p_title ilike '%' || trim(pos) || '%'
    );
$$;

-- ---------------------------------------------------------------------------
-- Seeker side (0051), rebuilt on the helpers.
-- ---------------------------------------------------------------------------
create or replace function public.recommended_jobs()
returns setof public.job_feed
language sql stable
set search_path = public as $$
  with me as (
    select p.id as uid, p.city, p.headline,
           p.desired_positions, p.desired_region, p.desired_district
    from public.profiles p
    where p.id = auth.uid()
  )
  select jf.*
  from public.job_feed jf
  cross join me
  cross join lateral (
    select (
        public.location_match_score(
          jf.region, jf.district, jf.city,
          me.desired_region, me.desired_district, me.city
        )
      + (case when public.title_matches_positions(
                     jf.title, me.headline, me.desired_positions)
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

-- ---------------------------------------------------------------------------
-- Employer side (0050), the same two signals from the other direction. Still
-- owner-gated, still returns only the safe card columns — `same_city` keeps its
-- name (both clients render it as the "same place" chip) and now means any
-- location hit, district or city or region.
-- ---------------------------------------------------------------------------
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
    select j.id, j.title, j.city, j.region, j.district, j.skills_required
    from public.jobs j
    where j.id = p_job_id and public.is_job_owner(j.id)   -- owner gate
  ),
  pool as (
    select
      p.id, p.full_name, p.headline, p.avatar_url, p.city,
      (p.worker_verified_at is not null) as worker_verified,
      p.availability,
      public.location_match_score(
        job.region, job.district, job.city,
        p.desired_region, p.desired_district, p.city
      ) as location_score,
      public.title_matches_positions(
        job.title, p.headline, p.desired_positions
      ) as headline_match,
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
      ( location_score
      + (case when headline_match then 3 else 0 end)
      + (case when exp_match then 2 else 0 end)
      + least(skills_matched, 3) ) as score
    from pool
  )
  select id, full_name, headline, avatar_url, city, worker_verified, availability,
         score, (location_score > 0) as same_city,
         (headline_match or exp_match) as role_match,
         skills_matched
  from scored
  where score > 0
  order by score desc, worker_verified desc, full_name
  limit 24;
$$;

revoke all on function public.recommended_candidates(uuid) from anon;
grant execute on function public.recommended_candidates(uuid) to authenticated;
