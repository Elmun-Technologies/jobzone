-- 0024_response_settings.sql
-- hh-style posting "response settings": an inclusive disability-friendly marker,
-- a require-cover-letter gate, an accept-incomplete-resume marker, and an
-- optional contact phone shown on the listing.

alter table public.jobs
  add column if not exists require_cover_letter   boolean not null default false,
  add column if not exists disability_friendly    boolean not null default false,
  add column if not exists allow_incomplete_resume boolean not null default false,
  add column if not exists show_phone_on_listing  boolean not null default false,
  add column if not exists contact_phone          text;

-- The disability collection only ever queries the `true` slice.
create index if not exists jobs_disability_friendly_idx
  on public.jobs (disability_friendly)
  where disability_friendly = true;

-- Recreate the seeker feed so `j.*` re-exposes the new columns (the 0021/0023
-- expansion froze the list). Drop first — `create or replace view` rejects the
-- column-order shift (42P16). Only the meili-reindex edge fn reads this view.
drop view if exists public.job_feed;
create view public.job_feed
  with (security_invoker = true) as
  select
    j.*,
    (j.boosted_until is not null and j.boosted_until > now()) as boost_active,
    c.name        as company_name,
    c.logo_url    as company_logo_url,
    c.is_verified as company_is_verified,
    cat.name      as category_name
  from public.jobs j
  join public.companies c on c.id = j.company_id
  left join public.job_categories cat on cat.id = j.category_id;
