-- Resume builder step 3: self-rated language levels, stored as a jsonb map of
-- language code -> CEFR-ish level, e.g. {"ru":"b1_b2","en":"a1_a2"}. Education
-- entries use the existing `educations` table (owner RLS from 0001).
alter table public.profiles
  add column if not exists languages jsonb not null default '{}'::jsonb;
