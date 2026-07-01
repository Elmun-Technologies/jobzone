-- 0035_saved_searches.sql
-- Saved job searches ("Obunalar"): a seeker stores search criteria to re-run.
-- Owner-scoped; the client stamps profile_id = auth.uid() on insert (RLS
-- enforces it). Notifying on new matches is a later follow-up.

create table if not exists public.saved_searches (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  name        text not null,
  keywords    text,
  city        text,
  created_at  timestamptz not null default now()
);
create index if not exists saved_searches_profile_idx
  on public.saved_searches (profile_id, created_at desc);

alter table public.saved_searches enable row level security;
drop policy if exists "saved_searches own" on public.saved_searches;
create policy "saved_searches own"
  on public.saved_searches for all to authenticated
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);
