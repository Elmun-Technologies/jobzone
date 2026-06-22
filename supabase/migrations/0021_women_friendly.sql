-- 0021_women_friendly.sql
-- Employer opt-in marker that a role offers women-friendly conditions (safe
-- environment, flexible hours). Powers the "Women-friendly" quick-find
-- collection. Inclusive/opt-in — NOT an exclusionary "women only" flag, and
-- not self-discoverable as gender-based hiring criteria.

alter table public.jobs
  add column if not exists women_friendly boolean not null default false;

-- Partial index: the collection only ever queries the `true` slice.
create index if not exists jobs_women_friendly_idx
  on public.jobs (women_friendly)
  where women_friendly = true;

-- Recreate the seeker feed so `j.*` picks up `women_friendly` (and any other
-- jobs columns added since 0011, which froze the previous `*` expansion). Drop
-- first — `create or replace view` rejects the column-order shift (42P16).
-- Nothing depends on this view except the meili-reindex edge fn, which reads
-- it with `select *`, so re-exposing more columns is safe.
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
