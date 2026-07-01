-- 0033_wallet.sql
-- Employer wallet ("Hamyon"): a company-scoped ledger of credits (top-ups,
-- bonuses, refunds) and debits (spend on promotions). Balance is the sum of
-- completed entries. Mirrors the promotion_orders security model: a client can
-- create only a `pending` top-up request for its own company and can never flip
-- it to `completed` (no update/delete policy) — so a user cannot self-credit.
-- Idempotent where practical.

create table if not exists public.wallet_transactions (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies(id) on delete cascade,
  kind         text not null check (kind in ('topup','spend','refund','bonus')),
  -- Signed amount: positive = credit, negative = debit.
  amount_uzs   numeric not null,
  currency     text not null default 'UZS',
  status       text not null default 'pending'
                 check (status in ('pending','completed','cancelled')),
  description  text,
  external_ref text,
  created_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists wallet_transactions_company_idx
  on public.wallet_transactions (company_id, created_at desc);

alter table public.wallet_transactions enable row level security;

drop policy if exists "wallet readable by company owner" on public.wallet_transactions;
create policy "wallet readable by company owner"
  on public.wallet_transactions for select to authenticated
  using (exists (
    select 1 from public.companies c
    where c.id = company_id and c.owner_id = auth.uid()));

-- A client may only request a top-up: a positive, pending credit for its own
-- company. Completing it (status -> completed) is service-role only (the
-- payment webhook), exactly like promotion_orders.
drop policy if exists "wallet insert pending topup by owner" on public.wallet_transactions;
create policy "wallet insert pending topup by owner"
  on public.wallet_transactions for insert to authenticated
  with check (
    kind = 'topup'
    and status = 'pending'
    and amount_uzs > 0
    and created_by = auth.uid()
    and exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = auth.uid()));
-- No update/delete policy: balances move only via service-role writes.

-- Read model: per-company balance from completed entries. security_invoker so
-- the underlying RLS select policy confines each owner to their own company.
create or replace view public.wallet_balances
  with (security_invoker = true) as
  select
    company_id,
    coalesce(sum(amount_uzs), 0) as balance_uzs
  from public.wallet_transactions
  where status = 'completed'
  group by company_id;
