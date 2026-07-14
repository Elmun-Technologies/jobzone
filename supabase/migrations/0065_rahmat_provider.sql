-- 0065_rahmat_provider.sql
-- Adds Rahmat (Multicard) as a third payment provider alongside Payme + Click.
-- Rahmat is a white-label front for Multicard's mesh.multicard.uz acquiring rail;
-- from Yolla's side it's the same shape as click-merchant/payme-merchant — an
-- edge function creates an invoice via Multicard's API and Multicard calls us
-- back to confirm payment, which flips the promotion_orders row to 'paid' and
-- the existing apply_promotion trigger publishes the draft vacancy.
--
-- Only change here is the provider CHECK constraint on payment_transactions so
-- a 'rahmat' row can be inserted. Idempotent (drop-if-exists + add).

alter table public.payment_transactions
  drop constraint if exists payment_transactions_provider_check;
alter table public.payment_transactions
  add constraint payment_transactions_provider_check
  check (provider in ('payme', 'click', 'rahmat'));
