-- 0066_publish_payment_guard.sql
-- Server-side enforcement of "first vacancy free, then pay-per-listing".
--
-- Until now the rule lived only in the clients (web createJob/updateJobStatus,
-- mobile _submit/_publishDraft). The jobs RLS policy ("full access for poster")
-- lets an owner UPDATE their own row, so a direct PostgREST call — or any
-- client that predates the paywall — could flip a draft to 'open' and publish
-- for free. Real money needs the rule in the database:
--
--   * entering the market (status becomes 'open' for the first time in a job's
--     life) is allowed for an authenticated client only if it's the company's
--     FIRST published listing, or the job carries a PAID tier order;
--   * re-opening a job that has already been live (jobs.first_published_at)
--     stays free — it was paid for (or was the free first) when it went live;
--   * service contexts (cron/definer functions, seeds, migrations — no
--     auth.uid()), the paid-publish path (app.applying_promotion flag, set by
--     apply_promotion) and admins are exempt;
--   * publish_due_jobs() (scheduled publishing) becomes payment-aware: a due
--     but unpaid 2nd+ draft is parked (publish_at cleared) with a notification
--     instead of silently going live for free.

-- ---------------------------------------------------------------------------
-- 1. Track a job's first go-live, so "reopen closed" is distinguishable from
--    "sneak a never-published job into the market".
-- ---------------------------------------------------------------------------
alter table public.jobs
  add column if not exists first_published_at timestamptz;

-- Backfill: anything already on the market (open or closed) was published
-- under the old (pre-paywall) rules; posted_at is the closest go-live stamp.
update public.jobs
   set first_published_at = posted_at
 where status <> 'draft'
   and first_published_at is null;

-- ---------------------------------------------------------------------------
-- 2. The guard trigger.
-- ---------------------------------------------------------------------------
create or replace function public.guard_job_publish()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only the transition INTO 'open' is gated; edits to a live job, drafts,
  -- closes etc. pass through untouched.
  if new.status <> 'open' then
    return new;
  end if;
  if TG_OP = 'UPDATE' and old.status = 'open' then
    return new;  -- already live; this is an edit, not a market entry
  end if;

  -- Going live now: stamp the first publish (kept across close/reopen).
  if TG_OP = 'UPDATE' then
    new.first_published_at := coalesce(old.first_published_at, now());
    -- Re-entry of a previously-live job (close -> reopen) is free.
    if old.first_published_at is not null then
      return new;
    end if;
  else
    new.first_published_at := coalesce(new.first_published_at, now());
  end if;

  -- Exemptions: service contexts (cron/seeds/service role have no auth uid),
  -- the paid-publish path, and admins.
  if auth.uid() is null then
    return new;
  end if;
  if coalesce(current_setting('app.applying_promotion', true), '0') = '1' then
    return new;
  end if;
  if public.is_admin() then
    return new;
  end if;

  -- First listing is free: the company has nothing else on the market yet.
  if not exists (
    select 1 from public.jobs j
     where j.company_id = new.company_id
       and j.id <> new.id
       and j.first_published_at is not null
  ) then
    return new;
  end if;

  -- 2nd+ listing: must carry a paid per-listing (tier) order. Normally the
  -- paid path arrives via apply_promotion (flag above); this keeps a direct
  -- "already paid" publish valid too.
  if exists (
    select 1
      from public.promotion_orders o
      join public.promotion_products p on p.code = o.product_code
     where o.job_id = new.id
       and o.status = 'paid'
       and p.kind = 'tier'
  ) then
    return new;
  end if;

  raise exception 'payment_required';
end;
$$;

drop trigger if exists trg_guard_job_publish on public.jobs;
create trigger trg_guard_job_publish
  before insert or update on public.jobs
  for each row execute function public.guard_job_publish();

-- ---------------------------------------------------------------------------
-- 3. Payment-aware scheduled publishing. A due draft goes live only if it's
--    the company's first listing or it's paid; otherwise it's parked (the
--    schedule is cleared so it stops re-matching) and the employer is told to
--    pay-publish it from "My jobs". Definer + no auth uid → guard-exempt, so
--    the eligibility rules are re-stated here explicitly.
-- ---------------------------------------------------------------------------
create or replace function public.publish_due_jobs()
  returns integer
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_count integer := 0;
  r record;
begin
  for r in
    select j.id, j.company_id, j.posted_by, j.title
      from public.jobs j
     where j.status = 'draft'
       and j.publish_at is not null
       and j.publish_at <= now()
       for update skip locked
  loop
    if not exists (
         select 1 from public.jobs x
          where x.company_id = r.company_id
            and x.id <> r.id
            and x.first_published_at is not null)
       or exists (
         select 1
           from public.promotion_orders o
           join public.promotion_products p on p.code = o.product_code
          where o.job_id = r.id
            and o.status = 'paid'
            and p.kind = 'tier')
    then
      update public.jobs
         set status = 'open', publish_at = null, posted_at = now()
       where id = r.id;
      v_count := v_count + 1;
    else
      -- Unpaid 2nd+ listing on a schedule: never silently free-publish. Park
      -- it and notify — publishing from "My jobs" runs the tier + pay flow.
      update public.jobs
         set publish_at = null
       where id = r.id;
      insert into public.notifications (recipient_id, type, title, body, data)
      values (
        r.posted_by,
        'system',
        r.title,
        'Rejalashtirilgan eʼlonni chiqarish uchun toʻlov kerak — «Mening vakansiyalarim»dan tarif tanlab toʻlang.',
        jsonb_build_object('job_id', r.id, 'reason', 'payment_required')
      );
    end if;
  end loop;
  return v_count;
end;
$$;
