-- 0055_admin_finance.sql
-- Finance oversight: lets the technical team settle/cancel pending wallet
-- top-ups, settle/cancel/refund promotion orders, and retune promotion
-- pricing from the panel — closing the "service-role only" gaps noted in
-- 0033_wallet.sql and 0011_monetization.sql. wallet_transactions and
-- promotion_orders have no client UPDATE policy at all (RLS default-denies
-- it) and promotion_products has no authenticated write policy, so these
-- SECURITY DEFINER RPCs are the only path to change them — no guard trigger
-- is needed the way job_categories/profiles needed one, since there's no
-- pre-existing owner-update policy for a client to route around.

create or replace function public.admin_set_topup_status(p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_kind text;
  v_from text;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_status not in ('completed', 'cancelled') then
    raise exception 'invalid status';
  end if;
  select kind, status into v_kind, v_from
    from public.wallet_transactions where id = p_id;
  if v_kind is null then raise exception 'transaction not found'; end if;
  if v_kind <> 'topup' or v_from <> 'pending' then
    raise exception 'only a pending topup can be settled';
  end if;
  update public.wallet_transactions
    set status = p_status,
        completed_at = case when p_status = 'completed' then now() else completed_at end
    where id = p_id;
  perform public.admin_audit(
    'wallet.set_topup_status', 'wallet_transactions', p_id::text,
    jsonb_build_object('status', p_status)
  );
end;
$$;
grant execute on function public.admin_set_topup_status(uuid, text) to authenticated;

-- Setting status = 'paid' rides trg_apply_promotion (0011), which fires on
-- this same UPDATE and applies the job boost automatically — no boost logic
-- duplicated here.
create or replace function public.admin_set_order_status(p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_from text;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_status not in ('paid', 'cancelled', 'refunded') then
    raise exception 'invalid status';
  end if;
  select status into v_from from public.promotion_orders where id = p_id;
  if v_from is null then raise exception 'order not found'; end if;
  update public.promotion_orders set status = p_status where id = p_id;
  perform public.admin_audit(
    'order.set_status', 'promotion_orders', p_id::text,
    jsonb_build_object('status', p_status, 'from', v_from)
  );
end;
$$;
grant execute on function public.admin_set_order_status(uuid, text) to authenticated;

create or replace function public.admin_set_product_price(
  p_code text, p_price_uzs numeric, p_is_active boolean
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_price_uzs is null or p_price_uzs < 0 then
    raise exception 'price must be >= 0';
  end if;
  update public.promotion_products
    set price_uzs = p_price_uzs, is_active = coalesce(p_is_active, is_active)
    where code = p_code;
  if not found then raise exception 'product not found'; end if;
  perform public.admin_audit(
    'product.set_price', 'promotion_products', p_code,
    jsonb_build_object('price_uzs', p_price_uzs, 'is_active', p_is_active)
  );
end;
$$;
grant execute on function public.admin_set_product_price(text, numeric, boolean) to authenticated;
