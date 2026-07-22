-- 0069: indexes for the hot read paths, so the feed and search stay fast as the
-- jobs table grows from hundreds to 100k+ rows. Today the jobs table is small,
-- so plain (non-CONCURRENT) CREATE INDEX is instant; on a large live table you'd
-- reach for CREATE INDEX CONCURRENTLY (which can't run inside a migration txn).
-- All guarded with IF NOT EXISTS so this is safe to re-run.

-- Trigram search --------------------------------------------------------------
-- The seeker search does ILIKE '%term%' on job title, company name and category
-- name (getOpenJobs / getJobCount build a PostgREST .or over the three). A
-- leading-wildcard ILIKE cannot use a btree — without trigram GIN it full-scans
-- the joined view on every keystroke-driven "N vakansiya" count. pg_trgm gives
-- each ILIKE an index to stand on.
create extension if not exists pg_trgm with schema extensions;

create index if not exists jobs_title_trgm_idx
  on public.jobs using gin (title extensions.gin_trgm_ops);

create index if not exists companies_name_trgm_idx
  on public.companies using gin (name extensions.gin_trgm_ops);

create index if not exists job_categories_name_trgm_idx
  on public.job_categories using gin (name extensions.gin_trgm_ops);

-- Hot feed ordering -----------------------------------------------------------
-- The home/explore/category feed is job_feed WHERE status='open'
-- ORDER BY boost_active DESC, posted_at DESC LIMIT n. status='open' is
-- low-selectivity (most rows are open), so a plain jobs(status) index doesn't
-- help — the planner scans and sorts. This partial index materializes exactly
-- the open, non-blocked slice in posted_at order so the feed is an index scan +
-- limit. boost_active is time-relative (boosted_until > now()) so it can't be
-- pinned in a static index; the existing partial jobs_boosted_until_idx (0011)
-- covers the small boosted head, and the LIMIT keeps the residual sort cheap.
create index if not exists jobs_open_feed_idx
  on public.jobs (posted_at desc)
  where status = 'open' and blocked_at is null;

-- Region / facet filters ------------------------------------------------------
-- City is the primary region facet (region selector + /ish/[category]/[city]
-- landings) and getCities() derives the selector from it. Unindexed today, so a
-- city-filtered feed scans. Scoped to open jobs to match how it's queried.
create index if not exists jobs_open_city_idx
  on public.jobs (city)
  where status = 'open' and blocked_at is null and city is not null;
