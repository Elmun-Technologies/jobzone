-- 0023_job_requirements.sql
-- hh-style posting depth: driver-license categories, required languages, and
-- whether the stated pay is gross (before tax) or net (take-home).

alter table public.jobs
  add column if not exists driver_licenses text[] not null default '{}',
  add column if not exists languages jsonb not null default '[]',
  add column if not exists salary_gross boolean not null default true;

-- Recreate the seeker feed so `j.*` re-exposes the new columns (the 0021
-- expansion froze the column list). Drop first — `create or replace view`
-- rejects the column-order shift (42P16). Nothing depends on this view except
-- the meili-reindex edge fn (reads it with `select *`).
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
