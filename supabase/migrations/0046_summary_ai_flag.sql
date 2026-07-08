-- 0046_summary_ai_flag.sql
-- Marks whether a résumé's "About me" (profiles.summary, 0044) was produced by
-- the AI helper and left untouched. Set true when the seeker taps "Write with
-- AI"; cleared the moment they edit the text themselves (personalising = owning
-- it). Lets an employer-facing view later flag a purely-AI summary, and backs
-- the "keep it real — employers can tell" nudge in the wizard. Owner-writable
-- like the rest of the profile (existing profiles RLS confines updates).

alter table public.profiles
  add column if not exists summary_ai_generated boolean not null default false;
