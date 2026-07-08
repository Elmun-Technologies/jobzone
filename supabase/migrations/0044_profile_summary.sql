-- 0044_profile_summary.sql
-- A free-text professional summary ("men haqimda" / About me) for the seeker's
-- résumé. The résumé wizard's AI helper writes it from a few notes; it's what
-- makes a blue-collar résumé read as complete. Owner-writable like the rest of
-- the profile (existing profiles RLS already confines updates to auth.uid()).

alter table public.profiles add column if not exists summary text;
