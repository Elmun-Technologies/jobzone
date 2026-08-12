-- 0075_listing_tier_upgrade.sql
-- Lets an employer upgrade a vacancy that is ALREADY LIVE to a higher tier.
--
-- 0063 replaced the old time-boxed TOP/featured boosts with per-listing tiers
-- charged once at publish time, and deactivated every `top`/`featured` product.
-- But `create_listing_order` only accepts a DRAFT job, so from that moment the
-- only chance to buy visibility was the instant of publishing: an employer who
-- posted their free first vacancy — or paid Standart — had no way to buy Brend
-- or Premium for it afterwards. The web "Reklama" button on every open vacancy
-- led to a page that could sell nothing (its catalog read is empty by
-- construction after 0063) and offered to top up the wallet for "0 so'm".
--
-- The effect side already handles this correctly: apply_promotion()'s `tier`
-- branch only flips status when the job is a draft, and otherwise just stamps
-- boost_kind / boosted_until — exactly what an upgrade of a live listing needs.
-- So the only change here is the RPC's entry guard.
--
-- Rules:
--   draft → any tier (unchanged: this is the publish-and-pay path)
--   open  → only a STRICT upgrade of the current tier (null/standard < brand
--           < premium). Re-buying the same or a lower tier is rejected, so an
--           employer can never pay again for visibility they already have.
--   anything else (closed / expired / archived) → not_draft, as before.

create or replace function public.create_listing_order(
  p_job_id uuid,
  p_tier_code text
) returns table (order_id uuid, amount_uzs numeric)
language plpgsql security definer set search_path = public as $$
declare
  v_company_id uuid;
  v_status     text;
  v_boost_kind text;
  v_price      numeric;
  v_kind       text;
  v_order_id   uuid;
  v_have       int;
  v_want       int;
begin
  select j.company_id, j.status, j.boost_kind
    into v_company_id, v_status, v_boost_kind
    from public.jobs j
    join public.companies c on c.id = j.company_id
    where j.id = p_job_id and c.owner_id = auth.uid();
  if v_company_id is null then
    raise exception 'not_owner';
  end if;
  if v_status not in ('draft', 'open') then
    raise exception 'not_draft';
  end if;

  select price_uzs, kind into v_price, v_kind
    from public.promotion_products
    where code = p_tier_code and is_active = true;
  if v_price is null then
    raise exception 'unknown_product';
  end if;
  if v_kind <> 'tier' or v_price <= 0 then
    raise exception 'not_a_tier';
  end if;

  -- A live listing may only move UP. (Standard carries no visual treatment, so
  -- it ranks with "no tier" — buying it for an open job would charge for
  -- nothing.)
  if v_status = 'open' then
    v_have := case v_boost_kind
      when 'premium' then 2
      when 'brand'   then 1
      else 0
    end;
    v_want := case p_tier_code
      when 'tier_premium' then 2
      when 'tier_brand'   then 1
      else 0
    end;
    if v_want <= v_have then
      raise exception 'not_an_upgrade';
    end if;
  end if;

  -- Reuse the job's existing pending order (idempotent re-submit / tier change).
  select id into v_order_id
    from public.promotion_orders
    where job_id = p_job_id and status = 'pending'
    order by created_at desc
    limit 1;

  if v_order_id is null then
    insert into public.promotion_orders
      (company_id, job_id, product_code, amount_uzs, status, created_by)
    values
      (v_company_id, p_job_id, p_tier_code, v_price, 'pending', auth.uid())
    returning id into v_order_id;
  else
    update public.promotion_orders
      set product_code = p_tier_code, amount_uzs = v_price
      where id = v_order_id;
  end if;

  order_id := v_order_id;
  amount_uzs := v_price;
  return next;
end;
$$;

revoke all on function public.create_listing_order(uuid, text) from public;
grant execute on function public.create_listing_order(uuid, text) to authenticated;
