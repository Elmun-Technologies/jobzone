-- 0064_payment_transactions.sql
-- Provider-side payment records for direct pay-per-listing. Each row is a
-- Payme/Click transaction against a promotion_orders row, carrying the provider's
-- own transaction id + state so the merchant callbacks are idempotent and Payme's
-- state machine (create -> perform / cancel) has a home. Written ONLY by the
-- payment edge functions (service role); never exposed to clients.

create table if not exists public.payment_transactions (
  id              uuid primary key default gen_random_uuid(),
  provider        text not null check (provider in ('payme', 'click')),
  provider_txn_id text not null,
  order_id        uuid not null references public.promotion_orders(id) on delete cascade,
  amount_uzs      numeric not null,
  -- Payme state: 1 created, 2 performed (paid), -1 cancelled-before-perform,
  -- -2 cancelled-after-perform. Click uses 1 (prepared) -> 2 (confirmed).
  state           int not null default 1,
  reason          int,
  create_time     bigint,
  perform_time    bigint,
  cancel_time     bigint,
  created_at      timestamptz not null default now(),
  unique (provider, provider_txn_id)
);
create index if not exists payment_transactions_order_idx
  on public.payment_transactions (order_id);

alter table public.payment_transactions enable row level security;
-- No policies: only the service-role payment edge functions read/write this table.
