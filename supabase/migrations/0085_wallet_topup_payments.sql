-- 0085_wallet_topup_payments.sql
-- Close the money loop: make a wallet top-up payable by the same gateways that
-- already settle a listing/promotion order.
--
-- Until now `wallet_transactions` accepted only a *pending* client-created
-- top-up (0033), and the single path to `completed` was an admin pressing a
-- button in the finance panel (0055). Meanwhile the Payme/Click/Rahmat
-- callbacks knew how to settle exactly one thing: a `promotion_orders` row. So
-- an employer could ask to top up and then wait for a human — which meant the
-- Hamyon balance, and therefore `buy_promotion()` (0043), was unreachable
-- self-serve. This migration gives the gateways a second order kind.
--
-- Design: one resolve + one settle function, both SECURITY DEFINER and
-- service-role-only, that the four payment edge functions call instead of
-- touching tables directly. Each takes the order id the gateway echoes back
-- (`account.order_id` / `merchant_trans_id` / `invoice_id`) and works out for
-- itself whether it names a promotion order or a top-up.
--
--   • promotion → amount comes from the CATALOG (promotion_products.price_uzs),
--     exactly as the merchant functions computed it before, so a stored amount
--     can never under-charge; settling `paid` rides the existing
--     apply_promotion trigger (boost / publish).
--   • topup     → amount is the row's own (server-bounded by
--     create_topup_order below, never client-chosen at settle time); settling
--     `paid` marks it completed, which is what moves `wallet_balances`.

-- ---------------------------------------------------------------------------
-- 1. payment_transactions can now reference either kind of order
-- ---------------------------------------------------------------------------
-- The FK to promotion_orders was what made this table single-purpose. Dropping
-- it also drops its ON DELETE CASCADE — deliberately: a gateway transaction is
-- a financial record and should outlive the order it paid for.
alter table public.payment_transactions
  drop constraint if exists payment_transactions_order_id_fkey;

alter table public.payment_transactions
  add column if not exists order_kind text not null default 'promotion'
    check (order_kind in ('promotion', 'topup'));

comment on column public.payment_transactions.order_kind is
  'Which table order_id points at: promotion_orders, or a wallet_transactions top-up.';

-- ---------------------------------------------------------------------------
-- 2. The client's one call to start a top-up
-- ---------------------------------------------------------------------------
-- Mirrors create_listing_order (0063): ownership-checked, amount bounded
-- server-side, idempotent, and it returns the id the checkout URL is built
-- from. Re-using the company's existing pending top-up of the same amount is
-- what stops five taps on "Pay" from minting five pending rows — and, more
-- importantly, it means the two gateway attempts settle the SAME row, so the
-- balance can never be credited twice for one intent.
create or replace function public.create_topup_order(
  p_amount_uzs numeric,
  p_company_id uuid default null
) returns table (order_id uuid, amount_uzs numeric)
language plpgsql security definer set search_path = public as $$
declare
  v_min      numeric := 5000;         -- below this the gateway fee eats it
  v_max      numeric := 50000000;     -- 50 mln so'm per single top-up
  v_amount   numeric := round(coalesce(p_amount_uzs, 0));
  v_company  uuid;
  v_order    uuid;
begin
  -- Resolve the caller's company: explicit id when given (and owned), else the
  -- one they own. Same "callers never pass a company id" ergonomics the mobile
  -- wallet repository already relies on.
  if p_company_id is not null then
    select c.id into v_company from public.companies c
      where c.id = p_company_id and c.owner_id = auth.uid();
  else
    select c.id into v_company from public.companies c
      where c.owner_id = auth.uid()
      order by c.created_at
      limit 1;
  end if;
  if v_company is null then
    raise exception 'not_owner';
  end if;

  if v_amount < v_min or v_amount > v_max then
    raise exception 'amount_out_of_range';
  end if;

  select t.id into v_order
    from public.wallet_transactions t
    where t.company_id = v_company
      and t.kind = 'topup'
      and t.status = 'pending'
      and t.amount_uzs = v_amount
    order by t.created_at desc
    limit 1;

  if v_order is null then
    insert into public.wallet_transactions
      (company_id, kind, amount_uzs, status, description, created_by)
    values
      (v_company, 'topup', v_amount, 'pending', 'Hamyonni to''ldirish', auth.uid())
    returning id into v_order;
  end if;

  order_id := v_order;
  amount_uzs := v_amount;
  return next;
end;
$$;

revoke all on function public.create_topup_order(numeric, uuid) from public;
grant execute on function public.create_topup_order(numeric, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. What the gateways see: one order, whatever table it lives in
-- ---------------------------------------------------------------------------
-- `status` is normalized to the promotion_orders vocabulary
-- (pending | paid | cancelled) so the merchant functions keep one state
-- machine. `owner_id` lets rahmat-invoice re-check ownership before creating
-- an invoice for someone else's order.
create or replace function public.gateway_order(p_order_id uuid)
returns table (
  order_id   uuid,
  kind       text,
  amount_uzs numeric,
  status     text,
  owner_id   uuid
)
language plpgsql security definer set search_path = public as $$
begin
  -- Promotion / listing-tier order: the price is the catalog's, never the row's.
  return query
    select o.id,
           'promotion'::text,
           p.price_uzs,
           o.status,
           c.owner_id
      from public.promotion_orders o
      join public.companies c on c.id = o.company_id
      left join public.promotion_products p on p.code = o.product_code
     where o.id = p_order_id;
  if found then return; end if;

  return query
    select t.id,
           'topup'::text,
           t.amount_uzs,
           case t.status
             when 'completed' then 'paid'
             when 'cancelled' then 'cancelled'
             else 'pending'
           end,
           c.owner_id
      from public.wallet_transactions t
      join public.companies c on c.id = t.company_id
     where t.id = p_order_id
       and t.kind = 'topup';
end;
$$;

revoke all on function public.gateway_order(uuid) from public;
grant execute on function public.gateway_order(uuid) to service_role;

-- Settle an order from a gateway callback. Returns true when this call is what
-- changed the row, so a replayed callback is a no-op rather than a double
-- credit. Only the payment edge functions (service role) may call it.
create or replace function public.gateway_settle_order(
  p_order_id     uuid,
  p_status       text,
  p_external_ref text default null
) returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_changed  int := 0;
  v_company  uuid;
  v_amount   numeric;
  v_status   text;
  v_balance  numeric;
begin
  -- 'refunded' is the cancel-after-perform case (Payme state -2): the money was
  -- taken and is being given back, which is a different fact from "never paid".
  if p_status not in ('paid', 'cancelled', 'refunded') then
    raise exception 'invalid status';
  end if;

  -- Promotion / listing order. Flipping to `paid` fires apply_promotion (0011),
  -- which applies the boost or publishes the paid vacancy. A cancel may also
  -- reach an already-paid order (refund), matching the previous behavior of
  -- the merchant functions.
  if exists (select 1 from public.promotion_orders where id = p_order_id) then
    update public.promotion_orders
       set status = p_status,
           paid_at = case when p_status = 'paid' then now() else paid_at end,
           external_ref = coalesce(p_external_ref, external_ref)
     where id = p_order_id
       and status = case when p_status = 'paid' then 'pending' else status end
       and status in ('pending', 'paid');
    get diagnostics v_changed = row_count;
    return v_changed > 0;
  end if;

  select t.company_id, t.amount_uzs, t.status
    into v_company, v_amount, v_status
    from public.wallet_transactions t
   where t.id = p_order_id and t.kind = 'topup';
  if v_company is null then
    return false;   -- unknown order: nothing this function can settle
  end if;

  if p_status = 'paid' then
    update public.wallet_transactions
       set status = 'completed',
           completed_at = now(),
           external_ref = coalesce(p_external_ref, external_ref)
     where id = p_order_id
       and status = 'pending';
    get diagnostics v_changed = row_count;
    return v_changed > 0;
  end if;

  -- Cancel / refund. A still-pending top-up cancels freely.
  if v_status = 'pending' then
    update public.wallet_transactions
       set status = 'cancelled'
     where id = p_order_id and status = 'pending';
    get diagnostics v_changed = row_count;
    return v_changed > 0;
  end if;

  -- Cancel-after-perform (Payme state -2): the credit already landed and may
  -- already have been spent. Reversing it is only safe while the balance can
  -- absorb it; otherwise leave the money in place and let the finance panel
  -- settle it as a refund, rather than silently pushing a company negative.
  if v_status = 'completed' then
    perform pg_advisory_xact_lock(hashtext(v_company::text));
    select coalesce(sum(amount_uzs), 0) into v_balance
      from public.wallet_transactions
     where company_id = v_company and status = 'completed';
    if v_balance - v_amount < 0 then
      raise warning 'topup % cancelled after spend; needs a manual refund', p_order_id;
      return false;
    end if;
    update public.wallet_transactions
       set status = 'cancelled'
     where id = p_order_id and status = 'completed';
    get diagnostics v_changed = row_count;
    return v_changed > 0;
  end if;

  return false;
end;
$$;

revoke all on function public.gateway_settle_order(uuid, text, text) from public;
grant execute on function public.gateway_settle_order(uuid, text, text) to service_role;
