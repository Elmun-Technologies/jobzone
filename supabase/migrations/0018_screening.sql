-- 0018_screening.sql
-- Screening questions authored with a job (hh-style "вопросы к кандидату").
-- Stored as jsonb on the job; candidate answers reuse the existing
-- applications.answers jsonb (keyed by question id). Owner CRUD on jobs covers
-- authoring, applicant insert covers answers, and the employer reads answers
-- via the existing is_job_owner select policy — so no new RLS is needed.
alter table public.jobs
  add column if not exists screening_questions jsonb not null default '[]'::jsonb;
