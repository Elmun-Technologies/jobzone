-- 0019_worker_reviews.sql
-- Reverse-direction reputation: employers rate workers they've actually
-- interacted with. Write-gated (anti-defamation) — only an employer who owns a
-- job the worker applied to may review them. Mirrors company_reviews +
-- company_rating_summary (0005).

create table if not exists public.worker_reviews (
  id          uuid primary key default gen_random_uuid(),
  worker_id   uuid not null references public.profiles(id) on delete cascade,
  author_id   uuid not null references public.profiles(id) on delete cascade,
  job_id      uuid references public.jobs(id) on delete set null,
  rating      int not null check (rating between 1 and 5),
  reliability int check (reliability is null or reliability between 1 and 5),
  body        text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (worker_id, author_id, job_id)
);
create index if not exists worker_reviews_worker_idx
  on public.worker_reviews (worker_id);
create trigger trg_worker_reviews_updated_at before update on public.worker_reviews
  for each row execute function public.set_updated_at();

alter table public.worker_reviews enable row level security;

drop policy if exists "worker_reviews readable by authenticated" on public.worker_reviews;
create policy "worker_reviews readable by authenticated"
  on public.worker_reviews for select to authenticated using (true);

-- Write only by the signed-in employer who owns a job the worker applied to.
drop policy if exists "worker_reviews write by hiring employer" on public.worker_reviews;
create policy "worker_reviews write by hiring employer"
  on public.worker_reviews for all to authenticated
  using (author_id = auth.uid())
  with check (
    author_id = auth.uid()
    and exists (
      select 1 from public.applications a
      where a.applicant_id = worker_id
        and public.is_job_owner(a.job_id)
    )
  );

-- Reputation summary (mirrors company_rating_summary). reliability_score is a
-- 0–100 blend of quality + reliability stars; no-show data folds in later.
create or replace view public.worker_reliability_summary
  with (security_invoker = true) as
  select worker_id,
         round(avg(rating)::numeric, 2)      as avg_rating,
         round(avg(reliability)::numeric, 2) as avg_reliability,
         count(*)                            as review_count,
         round(
           (coalesce(avg(rating), 0) * 0.6
            + coalesce(avg(reliability), avg(rating), 0) * 0.4) * 20
         )::int                              as reliability_score
  from public.worker_reviews
  group by worker_id;
