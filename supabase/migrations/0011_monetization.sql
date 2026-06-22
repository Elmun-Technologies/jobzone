-- 0011_monetization.sql
-- Paid job promotions: a product catalog, per-job orders, and secure boost
-- application. Basic posting stays free; promotions lift visibility.
-- Idempotent where practical.

-- ---------------------------------------------------------------------------
-- Catalog of promotion products (prices live here, not in the app).
-- ---------------------------------------------------------------------------
create table if not exists public.promotion_products (
  code          text primary key,
  name          text not null,
  description   text,
  kind          text not null check (kind in ('base','top','featured','ai')),
  price_uzs     numeric not null default 0,
  duration_days int,
  is_active     boolean not null default true,
  sort_order    int not null default 0,
  created_at    timestamptz not null default now()
);

alter table public.promotion_products enable row level security;
drop policy if exists "promotion_products readable by all" on public.promotion_products;
create policy "promotion_products readable by all"
  on public.promotion_products for select using (true);
-- Writes are service-role only (no authenticated policy).

insert into public.promotion_products
  (code, name, description, kind, price_uzs, duration_days, sort_order) values
  ('start',        'Start',          'Standart bepul e''lon',                 'base',     0,     null, 0),
  ('featured',     'Tezkor topish',  'Kategoriyada ajratib ko''rsatish',      'featured', 10000, 7,    1),
  ('top_3',        '3 kun TOP',      'Ro''yxat tepasida 3 kun',               'top',      15000, 3,    2),
  ('top_7',        '7 kun TOP',      'Ro''yxat tepasida 7 kun',               'top',      35000, 7,    3),
  ('top_30',       '30 kun TOP',     'Ro''yxat tepasida 30 kun',              'top',      99000, 30,   4),
  ('ai_screening', 'AI saralash',    'Nomzodlarni AI tartiblash (tez orada)', 'ai',       0,     null, 5)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- jobs: boost state. Written ONLY by apply_promotion() (see guard below).
-- ---------------------------------------------------------------------------
alter table public.jobs add column if not exists boosted_until timestamptz;
alter table public.jobs add column if not exists boost_kind    text;
create index if not exists jobs_boosted_until_idx
  on public.jobs (boosted_until) where boosted_until is not null;

-- Guard: clients may never set the boost columns directly (insert or update).
-- The legitimate path sets a transaction-local flag before writing.
create or replace function public.guard_job_boost()
returns trigger language plpgsql as $$
begin
  if coalesce(current_setting('app.applying_promotion', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.boosted_until := null;
    new.boost_kind := null;
  else
    new.boosted_until := old.boosted_until;
    new.boost_kind := old.boost_kind;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_job_boost on public.jobs;
create trigger trg_guard_job_boost
  before insert or update on public.jobs
  for each row execute function public.guard_job_boost();

-- ---------------------------------------------------------------------------
-- Orders. Client may create only a `pending` order for its own company and
-- can never flip it to `paid` (no update/delete policy) — so no self-boosting.
-- ---------------------------------------------------------------------------
create table if not exists public.promotion_orders (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies(id) on delete cascade,
  job_id       uuid references public.jobs(id) on delete set null,
  product_code text not null references public.promotion_products(code),
  amount_uzs   numeric not null default 0,
  currency     text not null default 'UZS',
  status       text not null default 'pending'
                 check (status in ('pending','paid','cancelled','refunded')),
  external_ref text,
  created_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now(),
  paid_at      timestamptz
);
create index if not exists promotion_orders_company_idx on public.promotion_orders (company_id);
create index if not exists promotion_orders_job_idx on public.promotion_orders (job_id);

alter table public.promotion_orders enable row level security;

drop policy if exists "orders readable by company owner" on public.promotion_orders;
create policy "orders readable by company owner"
  on public.promotion_orders for select to authenticated
  using (exists (
    select 1 from public.companies c
    where c.id = company_id and c.owner_id = auth.uid()));

drop policy if exists "orders insert pending by company owner" on public.promotion_orders;
create policy "orders insert pending by company owner"
  on public.promotion_orders for insert to authenticated
  with check (
    status = 'pending'
    and created_by = auth.uid()
    and exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = auth.uid()));
-- No update/delete policy: only service-role (admin / payment webhook) can mark paid.

-- When an order flips to `paid`, apply the boost to its job atomically.
create or replace function public.apply_promotion()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_days int;
  v_kind text;
begin
  if new.status = 'paid' and old.status is distinct from 'paid' then
    new.paid_at := coalesce(new.paid_at, now());
    if new.job_id is not null then
      select duration_days, kind into v_days, v_kind
        from public.promotion_products where code = new.product_code;
      if v_days is not null then
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
drop trigger if exists trg_apply_promotion on public.promotion_orders;
create trigger trg_apply_promotion
  before update on public.promotion_orders
  for each row execute function public.apply_promotion();

-- ---------------------------------------------------------------------------
-- Read model: expose boost state + a computed active flag to the seeker feed.
-- ---------------------------------------------------------------------------
-- Drop first: `jobs` gained boost columns above, so `j.*` shifts the view's
-- column order — `create or replace view` rejects the rename (42P16). Nothing
-- in the DB depends on this view (only the meili-reindex edge fn reads it).
drop view if exists public.job_feed;
create view public.job_feed
  with (security_invoker = true) as
  select
    j.*,
    (j.boosted_until is not null and j.boosted_until > now()) as boost_active,
    c.name        as company_name,
    c.logo_url    as company_logo_url,
    c.is_verified as company_is_verified,
    cat.name      as category_name
  from public.jobs j
  join public.companies c on c.id = j.company_id
  left join public.job_categories cat on cat.id = j.category_id;
