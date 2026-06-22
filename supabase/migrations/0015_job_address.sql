-- 0015_job_address.sql
-- Optional textual work address to accompany the map pin (jobs.lat/lng already
-- exist) — "Адрес работы" in the hh-style flow.
alter table public.jobs add column if not exists address_text text;
