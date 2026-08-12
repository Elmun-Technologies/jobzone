-- 0076_scheduled_paid_publish.sql
-- Paying for a SCHEDULED vacancy must not publish it immediately.
--
-- apply_promotion()'s `tier` branch (0063) publishes on payment:
--
--   set status = case when status = 'draft' then 'open' else status end,
--       posted_at = coalesce(posted_at, now())
--
-- That is right for the ordinary pay-to-publish flow, where the draft exists
-- only because it is waiting to be paid for. But an employer who schedules a
-- vacancy for next Monday also gets a draft — one carrying `publish_at`. With
-- the rule above, the moment their payment cleared the vacancy would go live
-- on the spot, days early, silently overriding the time they picked.
--
-- Nothing hit this yet only because the clients never charged for a scheduled
-- post at all: the mobile post screen computes its pay gate from the effective
-- status ('draft' when scheduled), so a 2nd+ scheduled vacancy created no
-- order. It then told the employer "scheduled" while publish_due_jobs() (0066)
-- correctly refused to free-publish it at the due time — parking it instead.
-- The client fix is to charge for it up front, which makes this ordering bug
-- reachable, so the guard belongs here first.
--
-- After this, a paid scheduled draft keeps its schedule and its tier, and
-- publish_due_jobs() publishes it when due — it already treats a paid tier
-- order as sufficient, so no change is needed there.

create or replace function public.apply_promotion()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_days int;
  v_kind text;
  v_tier text;
  v_scheduled boolean;
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

        -- A draft the employer scheduled for a future time is NOT published
        -- here — it keeps its schedule and its tier, and publish_due_jobs()
        -- takes it live when due (it accepts a paid tier order as payment).
        select j.status = 'draft'
               and j.publish_at is not null
               and j.publish_at > now()
          into v_scheduled
          from public.jobs j where j.id = new.job_id;

        perform set_config('app.applying_promotion', '1', true);
        update public.jobs
          set status     = case
                when coalesce(v_scheduled, false) then status
                when status = 'draft' then 'open'
                else status
              end,
              posted_at  = case
                when coalesce(v_scheduled, false) then posted_at
                else coalesce(posted_at, now())
              end,
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
