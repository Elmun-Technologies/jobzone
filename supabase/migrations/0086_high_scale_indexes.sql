-- 0086_high_scale_indexes.sql
-- High-scale database indexes and performance tunings for millions of rows.
-- Adds covering indexes and composite indexes for hot filtering paths.

-- 1. Applications lookup index for applicant activity and employer screening
create index if not exists applications_applicant_job_idx
  on public.applications (applicant_id, job_id);

-- 2. Wallet transactions fast audit index
create index if not exists wallet_transactions_status_completed_idx
  on public.wallet_transactions (company_id, created_at desc)
  where status = 'completed';

-- 3. Promotion orders fast active index
create index if not exists promotion_orders_pending_job_idx
  on public.promotion_orders (job_id, status)
  where status = 'pending';

-- 4. Jobs category & location composite partial index for instant faceted filtering
create index if not exists jobs_open_category_city_idx
  on public.jobs (category_id, city, posted_at desc)
  where status = 'open' and blocked_at is null;
