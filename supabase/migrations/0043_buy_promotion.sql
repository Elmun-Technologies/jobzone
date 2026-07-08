-- 0043_buy_promotion.sql
-- One-call "buy a promotion from the wallet" RPC, so an employer can boost
-- (reklama) their own live vacancy from the web/app in a single atomic step.
--
-- Until now boosts only applied through apply_promotion() when a promotion_order
-- was flipped to `paid` — a service-role/payment-webhook action. There was no
-- self-serve path that spends the Hamyon balance the way createJob does for
-- posting. buy_promotion() fills that gap, mirroring adjust_wallet()'s
-- privileged-write pattern: security-definer, ownership-checked, advisory-locked,
-- balance-guarded, and it writes the boost columns under the same
-- `app.applying_promotion` flag that guard_job_boost() honors.
--
-- Atomic order of effects (all in one txn): debit wallet -> extend the job's
-- boost -> record a `paid` promotion_order for history. Inserting the order as
-- `paid` (not pending->update) deliberately does NOT re-fire apply_promotion()
-- (that trigger is BEFORE UPDATE), so the boost is applied exactly once, here.

create or replace function public.buy_promotion(
  p_job_id uuid,
  p_product_code text
) returns timestamptz
language plpgsql security definer set search_path = public as $$
declare
  v_company_id uuid;
  v_status     text;
  v_price      numeric;
  v_days       int;
  v_kind       text;
  v_balance    numeric;
  v_new_until  timestamptz;
begin
  -- 1. Resolve the job's company and confirm the caller owns it. RLS on jobs
  --    already limits visibility, but this is the authoritative gate for the
  --    definer context (which bypasses RLS).
  select j.company_id, j.status into v_company_id, v_status
    from public.jobs j
    join public.companies c on c.id = j.company_id
    where j.id = p_job_id and c.owner_id = auth.uid();
  if v_company_id is null then
    raise exception 'not_owner';
  end if;
  -- Only a live vacancy is worth boosting; a draft/closed job is hidden, so
  -- spending on it would be money down the drain. Publish first.
  if v_status <> 'open' then
    raise exception 'not_open';
  end if;

  -- 2. Read the product. Must be an active, time-boxed, paid promotion — never
  --    the free base tier / the job_post posting fee / the not-yet-live AI tier.
  select price_uzs, duration_days, kind into v_price, v_days, v_kind
    from public.promotion_products
    where code = p_product_code and is_active = true;
  if v_price is null then
    raise exception 'unknown_product';
  end if;
  if v_kind not in ('top', 'featured') or v_days is null or v_price <= 0 then
    raise exception 'not_purchasable';
  end if;

  -- 3. Serialize spends for this company (matches adjust_wallet's lock, so a
  --    promotion and a paid post can't both pass the balance check), read the
  --    completed-entry balance, and require enough funds.
  perform pg_advisory_xact_lock(hashtext(v_company_id::text));

  select coalesce(sum(amount_uzs), 0) into v_balance
    from public.wallet_transactions
    where company_id = v_company_id and status = 'completed';
  if v_balance - v_price < 0 then
    raise exception 'insufficient_funds';
  end if;

  -- 4. Debit the wallet (a completed spend row — same shape adjust_wallet writes).
  insert into public.wallet_transactions
    (company_id, kind, amount_uzs, status, description, created_by, completed_at)
  values
    (v_company_id, 'spend', -v_price, 'completed',
     'Reklama: ' || p_product_code, auth.uid(), now());

  -- 5. Apply the boost directly, under the guard flag guard_job_boost() checks.
  --    Extend from the later of "now" and any still-running boost so stacking
  --    top-ups adds time instead of shrinking it.
  perform set_config('app.applying_promotion', '1', true);
  update public.jobs
    set boosted_until =
          greatest(coalesce(boosted_until, now()), now())
          + make_interval(days => v_days),
        boost_kind = v_kind
    where id = p_job_id
    returning boosted_until into v_new_until;
  perform set_config('app.applying_promotion', '0', true);

  -- 6. Record the purchase as a paid order (history / audit). Insert-as-paid
  --    does not re-fire apply_promotion() (BEFORE UPDATE only) — boost applied
  --    once, in step 5.
  insert into public.promotion_orders
    (company_id, job_id, product_code, amount_uzs, status, created_by, paid_at)
  values
    (v_company_id, p_job_id, p_product_code, v_price, 'paid', auth.uid(), now());

  return v_new_until;
end;
$$;

revoke all on function public.buy_promotion(uuid, text) from public;
grant execute on function public.buy_promotion(uuid, text) to authenticated;
