-- 0063_listing_tiers.sql
-- Per-listing visibility tiers, charged directly per vacancy (no wallet). The
-- first vacancy is free; from the 2nd onward the employer picks one of three
-- tiers, pays via Payme/Click, and the paid order publishes the draft vacancy
-- and stamps its tier:
--   tier_standard  39 900  plain paid listing        (boost_kind = null)
--   tier_brand     79 900  company logo lights up    (boost_kind = 'brand')
--   tier_premium   99 900  whole listing stands out  (boost_kind = 'premium')
--
-- Reuses the existing promotion_orders + apply_promotion machinery: a client
-- creates a `pending` order, a service-role/webhook flips it to `paid`, and the
-- BEFORE-UPDATE trigger applies the effect. Here we teach that trigger the new
-- `tier` kind (publish + stamp tier) alongside the legacy time-boxed boosts.
-- Idempotent where practical.

-- 1. Allow the new 'tier' kind on the catalog, retire the old self-serve boosts,
--    and seed the three tiers. (0011 seeds with `do nothing`, so prices for an
--    existing row must be an explicit upsert.)
alter table public.promotion_products
  drop constraint if exists promotion_products_kind_check;
alter table public.promotion_products
  add constraint promotion_products_kind_check
  check (kind in ('base', 'top', 'featured', 'ai', 'tier'));

update public.promotion_products set is_active = false
  where code in ('featured', 'top_3', 'top_7', 'top_30');

insert into public.promotion_products
  (code, name, description, kind, price_uzs, duration_days, sort_order) values
  ('tier_standard', 'Standart', 'Oddiy e''lon',                'tier', 39900, null, 10),
  ('tier_brand',    'Brend',    'Logotip yonib turadi',        'tier', 79900, null, 11),
  ('tier_premium',  'Premium',  'Butunlay ajralib turadi',     'tier', 99900, null, 12)
on conflict (code) do update set
  name = excluded.name, description = excluded.description, kind = excluded.kind,
  price_uzs = excluded.price_uzs, duration_days = excluded.duration_days,
  sort_order = excluded.sort_order, is_active = true;

-- 2. Teach apply_promotion() the `tier` kind. When a tier order is paid, publish
--    the draft vacancy (status open + posted_at) and stamp its listing tier —
--    all under the app.applying_promotion guard flag so guard_job_boost() lets
--    the boost columns through. The legacy duration-based boost path is kept
--    verbatim for any still-active top/featured orders.
create or replace function public.apply_promotion()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_days int;
  v_kind text;
  v_tier text;
begin
  if new.status = 'paid' and old.status is distinct from 'paid' then
    new.paid_at := coalesce(new.paid_at, now());
    if new.job_id is not null then
      select duration_days, kind into v_days, v_kind
        from public.promotion_products where code = new.product_code;

      if v_kind = 'tier' then
        -- Direct pay-per-listing: paying publishes the draft and sets its tier.
        -- Standard is a plain paid listing (no visual boost); brand/premium
        -- carry a permanent boost_kind the cards/map read. boosted_until is set
        -- so the tier reads as "active" for the life of the listing.
        v_tier := case new.product_code
          when 'tier_brand'   then 'brand'
          when 'tier_premium' then 'premium'
          else null
        end;
        perform set_config('app.applying_promotion', '1', true);
        update public.jobs
          set status     = case when status = 'draft' then 'open' else status end,
              posted_at  = coalesce(posted_at, now()),
              boost_kind = v_tier,
              boosted_until = case
                when v_tier is null then boosted_until
                else coalesce(expires_at, now() + interval '365 days')
              end
          where id = new.job_id;
        perform set_config('app.applying_promotion', '0', true);

      elsif v_days is not null then
        -- Legacy time-boxed boost (top/featured): extend from the later of now
        -- and any still-running boost.
        perform set_config('app.applying_promotion', '1', true);
        update public.jobs
          set boosted_until =
                greatest(coalesce(boosted_until, now()), now())
                + make_interval(days => v_days),
              boost_kind = v_kind
          where id = new.job_id;
        perform set_config('app.applying_promotion', '0', true);
      end if;
    end if;
  end if;
  return new;
end;
$$;

-- 3. create_listing_order(job, tier): the client's one call to start a paid
--    post. Verifies the caller owns the job and it is their DRAFT, resolves the
--    tier PRICE server-side (never trust a client amount), and inserts — or
--    reuses/retargets — a single `pending` order for that job. Returns the order
--    id + amount so the client can hand them to the Payme/Click checkout. The
--    payment webhook later flips the order to `paid`, which publishes the job.
create or replace function public.create_listing_order(
  p_job_id uuid,
  p_tier_code text
) returns table (order_id uuid, amount_uzs numeric)
language plpgsql security definer set search_path = public as $$
declare
  v_company_id uuid;
  v_status     text;
  v_price      numeric;
  v_kind       text;
  v_order_id   uuid;
begin
  select j.company_id, j.status into v_company_id, v_status
    from public.jobs j
    join public.companies c on c.id = j.company_id
    where j.id = p_job_id and c.owner_id = auth.uid();
  if v_company_id is null then
    raise exception 'not_owner';
  end if;
  if v_status <> 'draft' then
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
