-- 0060_job_feed_contact_phone.sql
-- P1 audit fix: job_feed selected `j.*`, so contact_phone shipped to every
-- viewer of every open job over the network regardless of
-- show_phone_on_listing — the UI only gated *display* of the number
-- (job_details_page.dart), but any client could already read the raw value
-- straight off the API response. Recreate with an explicit column list
-- (not `j.*`) so contact_phone is redacted server-side when the employer
-- opted out, and so a future sensitive column added to `jobs` doesn't
-- auto-leak through this view the same way.
--
-- Column list mirrors the jobs table as of 0058 (verified against every
-- `create table public.jobs` / `alter table public.jobs add column`
-- statement in the migration history — no columns have been dropped or
-- renamed). Same WHERE clause as 0039 (expiry + blocked-job/company filter).

-- recommended_jobs() is declared `returns setof public.job_feed` (0051, then
-- replaced in 0052), so it depends on this view's composite type and makes
-- `drop view job_feed` fail with 2BP01. Drop the function first, then recreate
-- it (with its latest, dismissed-jobs-aware body) after the view is rebuilt.
drop function if exists public.recommended_jobs();

drop view if exists public.job_feed;
create view public.job_feed
  with (security_invoker = true) as
  select
    j.id,
    j.company_id,
    j.posted_by,
    j.title,
    j.description,
    j.responsibilities,
    j.requirements,
    j.benefits,
    j.category_id,
    j.job_type,
    j.experience_level,
    j.working_model,
    j.location,
    j.country,
    j.city,
    j.lat,
    j.lng,
    j.salary_min,
    j.salary_max,
    j.currency,
    j.salary_period,
    j.skills_required,
    j.status,
    j.applicants_count,
    j.views_count,
    j.posted_at,
    j.expires_at,
    j.created_at,
    j.updated_at,
    j.boosted_until,
    j.boost_kind,
    j.payout_frequency,
    j.address_text,
    j.schedule_pattern,
    j.hours_per_day,
    j.night_shift,
    j.formalization,
    j.screening_questions,
    j.women_friendly,
    j.driver_licenses,
    j.languages,
    j.salary_gross,
    j.require_cover_letter,
    j.disability_friendly,
    j.allow_incomplete_resume,
    j.show_phone_on_listing,
    -- Redacted unless the employer opted in to showing it on the listing.
    case when j.show_phone_on_listing then j.contact_phone end as contact_phone,
    j.publish_at,
    j.region,
    j.district,
    j.age_min,
    j.age_max,
    j.preferred_gender,
    j.start_availability,
    j.salary_display,
    j.education_required,
    j.work_hours,
    j.blocked_at,
    j.blocked_by,
    j.blocked_reason,
    (j.boosted_until is not null and j.boosted_until > now()) as boost_active,
    c.name        as company_name,
    c.logo_url    as company_logo_url,
    c.is_verified as company_is_verified,
    cat.name      as category_name
  from public.jobs j
  join public.companies c on c.id = j.company_id
  left join public.job_categories cat on cat.id = j.category_id
  where (j.expires_at is null or j.expires_at > now())
    and j.blocked_at is null
    and c.blocked_at is null;

-- Recreate recommended_jobs() against the rebuilt view (dropped above so the
-- view could be replaced). Body is identical to 0052 (its latest definition);
-- `select jf.*` / `returns setof job_feed` pick up the new column list
-- automatically. Grants restored (a fresh function starts with none).
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
    and not exists (
      select 1 from public.dismissed_jobs d
      where d.job_id = jf.id and d.profile_id = me.uid
    )
  order by sc.score desc, jf.boost_active desc, jf.posted_at desc nulls last
  limit 30;
$$;

revoke all on function public.recommended_jobs() from anon;
grant execute on function public.recommended_jobs() to authenticated;
