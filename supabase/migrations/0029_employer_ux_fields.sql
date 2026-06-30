-- 0029_employer_ux_fields.sql
-- Competitor-parity UX fields on job postings (employer side).
-- Adds: cascading region/district location, candidate age & gender preference,
-- start-availability expectation, and salary display preference.

-- 1. New columns (all additive, safe to re-run).
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS region           text,
  ADD COLUMN IF NOT EXISTS district         text,
  ADD COLUMN IF NOT EXISTS age_min          int  DEFAULT 18,
  ADD COLUMN IF NOT EXISTS age_max          int,
  ADD COLUMN IF NOT EXISTS preferred_gender text DEFAULT 'any'
    CHECK (preferred_gender IN ('any', 'male', 'female')),
  ADD COLUMN IF NOT EXISTS start_availability text
    CHECK (start_availability IN ('immediate', 'one_week', 'two_weeks', 'one_month')),
  ADD COLUMN IF NOT EXISTS salary_display   text DEFAULT 'exact'
    CHECK (salary_display IN ('exact', 'negotiable', 'hidden'));

-- 2. Recreate job_feed so the new columns appear in j.*.
--    (PostgreSQL resolves j.* at view-creation time; a DROP+CREATE is required
--    after every ALTER TABLE on jobs.)
DROP VIEW IF EXISTS public.job_feed;
CREATE VIEW public.job_feed AS
  SELECT
    j.*,
    c.name       AS company_name,
    c.logo_url   AS company_logo_url,
    c.is_verified AS company_is_verified,
    cat.name     AS category_name,
    (j.boosted_until IS NOT NULL AND j.boosted_until > now()) AS boost_active
  FROM public.jobs j
  JOIN public.companies c ON c.id = j.company_id
  LEFT JOIN public.job_categories cat ON cat.id = j.category_id
  WHERE j.status = 'open'
    AND (j.publish_at IS NULL OR j.publish_at <= now());
