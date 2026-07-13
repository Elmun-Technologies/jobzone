-- 0062_company_follows.sql
-- "Подписки" (Obunalar): a seeker follows a company to keep track of its
-- active vacancies. Mirrors bookmarks / saved_searches exactly (owner-scoped,
-- the client stamps profile_id = auth.uid() on insert, RLS enforces it) so both
-- clients reuse the same read/write pattern.

create table if not exists public.company_follows (
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  company_id  uuid not null references public.companies(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (profile_id, company_id)
);
create index if not exists company_follows_profile_idx
  on public.company_follows (profile_id, created_at desc);
create index if not exists company_follows_company_idx
  on public.company_follows (company_id);

alter table public.company_follows enable row level security;
drop policy if exists "company_follows own" on public.company_follows;
create policy "company_follows own"
  on public.company_follows for all to authenticated
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);
