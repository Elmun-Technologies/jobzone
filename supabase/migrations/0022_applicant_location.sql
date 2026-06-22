-- 0022_applicant_location.sql
-- Expose worker coordinates to employers so the applicants screens can sort by
-- commute distance and plot candidates on a map. `profiles.lat/lng` already
-- exist (0001, set by the Manual-Location step); this only projects them into
-- the employer-facing public view.
--
-- Append-only `create or replace` (lat/lng added at the END of the existing
-- 0017 column list) — Postgres allows appending columns without a drop.
-- Privacy: coords get the same access this view already grants for city/country;
-- a later refinement could gate on is_open_to_work or coarsen precision.
create or replace view public.profiles_public
  with (security_invoker = true) as
  select id, full_name, headline, avatar_url, cover_url, city, country,
         is_open_to_work,
         (phone_verified_at is not null)  as phone_verified,
         (worker_verified_at is not null) as worker_verified,
         desired_pay_min, desired_pay_max, desired_pay_currency, availability,
         lat, lng
  from public.profiles;
