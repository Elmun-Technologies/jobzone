-- 0012_pay_details.sql
-- Richer pay info on a job posting (hh-style): broaden the pay basis
-- (salary_period) and add a payout frequency.

-- Pay basis ("Оплата"): allow shift/task/week alongside the time units.
alter table public.jobs drop constraint if exists jobs_salary_period_check;
alter table public.jobs
  add constraint jobs_salary_period_check
  check (
    salary_period is null
    or salary_period in ('hour','day','week','month','year','shift','task')
  );

-- Payout frequency ("Частота выплат").
alter table public.jobs
  add column if not exists payout_frequency text
  check (
    payout_frequency is null
    or payout_frequency in ('monthly','biweekly','weekly','daily')
  );
