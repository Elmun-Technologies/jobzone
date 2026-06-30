-- 0030_job_education_workhours.sql
-- Adds education requirement and work-hours fields to job postings.

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS education_required text DEFAULT 'none'
    CHECK (education_required IN ('none', 'secondary', 'specialized_secondary', 'higher')),
  ADD COLUMN IF NOT EXISTS work_hours text; -- e.g. '9:00–18:00'

-- Recreate job_feed so the new columns appear in j.*.
DROP VIEW IF EXISTS public.job_feed;
CREATE VIEW public.job_feed AS
  SELECT
    j.*,
    c.name        AS company_name,
    c.logo_url    AS company_logo_url,
    c.is_verified AS company_is_verified,
    cat.name      AS category_name,
    (j.boosted_until IS NOT NULL AND j.boosted_until > now()) AS boost_active
  FROM public.jobs j
  JOIN  public.companies c   ON c.id  = j.company_id
  LEFT JOIN public.job_categories cat ON cat.id = j.category_id
  WHERE j.status = 'open'
    AND (j.publish_at IS NULL OR j.publish_at <= now());
