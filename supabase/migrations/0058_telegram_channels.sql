-- 0058_telegram_channels.sql
-- Self-marketing pipeline: when a vacancy becomes publicly visible (status
-- 'open'), auto-post it to a Telegram channel scoped to its category + region
-- ("Haydovchilar — Toshkent", "Qurilish — Andijon", ...). The technical team
-- opens the channels, adds the bot as admin there, then maps chat_id ->
-- category/region from this admin CMS — no code change to add a channel.
--
-- Mirrors the 0053 category-CMS pattern (admin-gated security-definer RPCs,
-- admin_audit on every write) and the 0026/0040 notify-dispatch pattern
-- (AFTER trigger -> pg_net -> Edge Function, reading the target URL from
-- `private.app_secrets` with a `current_setting` fallback, no-op when
-- unconfigured so local/CI migrations always apply cleanly).

-- 1. Static per-category banner (the "mini banner" for channel posts). A
--    plain URL field — the team hosts/uploads the image themselves (any
--    public bucket/CDN) and pastes the link in the category CMS.
alter table public.job_categories
  add column if not exists banner_url text;

-- 2. category + region -> Telegram channel. `region is null` is a catch-all
--    channel for that category (used when no exact-region channel exists).
--    One channel per (category, region) pair.
create table if not exists public.telegram_channels (
  id          uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.job_categories(id) on delete cascade,
  region      text,
  chat_id     text not null,
  title       text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (category_id, region)
);
alter table public.telegram_channels enable row level security;
-- No client policies: the admin panel reads via the service-role key
-- (adminReadClient(), matching every other admin list) and writes only
-- through the security-definer RPCs below.

-- ---------------------------------------------------------------------------
-- Insert or update a channel mapping. p_id null -> insert; existing p_id ->
-- update in place. Admin-only, security definer (mirrors admin_upsert_category).
-- ---------------------------------------------------------------------------
create or replace function public.admin_upsert_telegram_channel(
  p_id          uuid default null,
  p_category_id uuid default null,
  p_region      text default null,
  p_chat_id     text default null,
  p_title       text default null,
  p_is_active   boolean default true
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_region text := nullif(trim(coalesce(p_region, '')), '');
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_category_id is null then raise exception 'category is required'; end if;
  if coalesce(trim(p_chat_id), '') = '' then raise exception 'chat_id is required'; end if;

  if p_id is null then
    insert into public.telegram_channels (category_id, region, chat_id, title, is_active)
    values (p_category_id, v_region, trim(p_chat_id),
            nullif(trim(coalesce(p_title, '')), ''), coalesce(p_is_active, true))
    returning id into v_id;
    perform public.admin_audit(
      'telegram_channel.create', 'telegram_channel', v_id::text,
      jsonb_build_object('category_id', p_category_id, 'region', v_region, 'chat_id', p_chat_id)
    );
  else
    update public.telegram_channels set
      category_id = p_category_id,
      region      = v_region,
      chat_id     = trim(p_chat_id),
      title       = nullif(trim(coalesce(p_title, '')), ''),
      is_active   = coalesce(p_is_active, true)
    where id = p_id
    returning id into v_id;
    if v_id is null then raise exception 'channel not found'; end if;
    perform public.admin_audit(
      'telegram_channel.update', 'telegram_channel', v_id::text,
      jsonb_build_object('category_id', p_category_id, 'region', v_region, 'chat_id', p_chat_id)
    );
  end if;

  return v_id;
end;
$$;
grant execute on function public.admin_upsert_telegram_channel(uuid, uuid, text, text, text, boolean)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Toggle a channel mapping active/inactive without deleting it.
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_telegram_channel_active(p_id uuid, p_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  update public.telegram_channels set is_active = p_active where id = p_id;
  if not found then raise exception 'channel not found'; end if;
  perform public.admin_audit(
    'telegram_channel.set_active', 'telegram_channel', p_id::text,
    jsonb_build_object('active', p_active)
  );
end;
$$;
grant execute on function public.admin_set_telegram_channel_active(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- Category CMS: add the banner URL to the existing upsert RPC (0053). New
-- trailing default-valued param keeps every existing named-arg caller intact.
-- ---------------------------------------------------------------------------
create or replace function public.admin_upsert_category(
  p_id uuid default null,
  p_name text default null,
  p_slug text default null,
  p_icon text default null,
  p_sort_order int default 0,
  p_is_active boolean default true,
  p_banner_url text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if coalesce(trim(p_name), '') = '' or coalesce(trim(p_slug), '') = '' then
    raise exception 'name and slug are required';
  end if;

  if p_id is null then
    insert into public.job_categories (name, slug, icon, sort_order, is_active, banner_url)
    values (
      trim(p_name), trim(p_slug), nullif(trim(coalesce(p_icon, '')), ''),
      coalesce(p_sort_order, 0), coalesce(p_is_active, true),
      nullif(trim(coalesce(p_banner_url, '')), '')
    )
    returning id into v_id;
    perform public.admin_audit(
      'category.create', 'job_category', v_id::text,
      jsonb_build_object('name', p_name, 'slug', p_slug)
    );
  else
    update public.job_categories set
      name = trim(p_name),
      slug = trim(p_slug),
      icon = nullif(trim(coalesce(p_icon, '')), ''),
      sort_order = coalesce(p_sort_order, 0),
      is_active = coalesce(p_is_active, true),
      banner_url = nullif(trim(coalesce(p_banner_url, '')), '')
    where id = p_id
    returning id into v_id;
    if v_id is null then raise exception 'category not found'; end if;
    perform public.admin_audit(
      'category.update', 'job_category', v_id::text,
      jsonb_build_object('name', p_name, 'slug', p_slug)
    );
  end if;

  return v_id;
end;
$$;
grant execute on function public.admin_upsert_category(uuid, text, text, text, int, boolean, text)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Auto-post trigger: fires when a job transitions INTO 'open' (a fresh
--    INSERT already open, or an UPDATE from draft/closed -> open — e.g.
--    `publish_due_jobs()` or the employer's "publish now"/reopen action).
--    Skips UPDATEs where the row was already open (editing an open vacancy
--    must not re-post it). No-ops until `telegram_channel_post_url` is set,
--    same as notify_dispatch, so migrations always apply cleanly.
-- ---------------------------------------------------------------------------
create or replace function public.telegram_channel_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url    text := coalesce(
    (select value from private.app_secrets where name = 'telegram_channel_post_url'),
    current_setting('app.telegram_channel_post_url', true));
  v_secret text := coalesce(
    (select value from private.app_secrets where name = 'edge_shared_secret'),
    current_setting('app.edge_shared_secret', true));
begin
  if v_url is null or v_url = '' then
    return new;   -- not configured (local/CI) -> no-op
  end if;
  if new.status <> 'open' then
    return new;
  end if;
  if TG_OP = 'UPDATE' and OLD.status = 'open' then
    return new;   -- already open before this write -> already posted
  end if;

  perform net.http_post(
    url     := v_url,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-edge-secret', coalesce(v_secret, '')),
    body    := jsonb_build_object('job_id', new.id)
  );
  return new;
end;
$$;

drop trigger if exists trg_telegram_channel_dispatch on public.jobs;
create trigger trg_telegram_channel_dispatch
  after insert or update on public.jobs
  for each row execute function public.telegram_channel_dispatch();
