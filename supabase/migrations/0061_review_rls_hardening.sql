-- 0061_review_rls_hardening.sql
-- P1 audit fixes: two review-table RLS gaps.
--
-- 1. company_reviews write policy gated only on `auth.uid() = author_id`, with
--    no check the author ever worked at / applied to the company — any
--    signed-up account could flood a competitor with 1-star reviews or
--    astroturf 5-star ones. worker_reviews (the reverse direction, 0019) was
--    already gated to a real hiring relationship; this brings company_reviews
--    to the same standard.
-- 2. worker_reviews SELECT policy let any authenticated user read every
--    worker's raw review body via `from('worker_reviews').select()` — the app
--    only ever consumes the aggregated worker_reliability_summary view, so
--    per-row bodies never needed to be client-exposed at all. Now scoped to
--    the worker being reviewed, the review's author, or an admin.

drop policy if exists "company_reviews write own" on public.company_reviews;
create policy "company_reviews write own"
  on public.company_reviews for all to authenticated
  using (auth.uid() = author_id)
  with check (
    auth.uid() = author_id
    and exists (
      select 1 from public.applications a
      join public.jobs j on j.id = a.job_id
      where a.applicant_id = auth.uid() and j.company_id = company_reviews.company_id
    )
  );

drop policy if exists "worker_reviews readable by authenticated" on public.worker_reviews;
create policy "worker_reviews readable by authenticated"
  on public.worker_reviews for select to authenticated
  using (
    public.is_admin()
    or auth.uid() = author_id
    or (auth.uid() = worker_id and hidden_at is null)
  );
