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
