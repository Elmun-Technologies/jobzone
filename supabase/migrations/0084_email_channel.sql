-- 0084_email_channel.sql
-- Email as a first-class delivery channel, alongside in-app / Telegram / push.
--
-- Until now `notification_settings` carried email_* columns that nothing ever
-- read: not a single message left the platform by email. This migration makes
-- email real end to end:
--
--   1. Preferences — adds the missing per-category switches (reviews,
--      marketing) and a per-user `unsubscribe_token` so every email can carry a
--      working one-click unsubscribe link (List-Unsubscribe), which is what
--      keeps a sending domain out of the spam folder.
--   2. `email_deliveries` — an append-only send log (service-role writes only).
--      It is both the audit trail and the idempotency key: `dedupe_key` makes
--      "the welcome email" a once-per-account fact even if the trigger fires
--      twice.
--   3. Alerts — the saved-search matcher now tags its notifications
--      (`data.alert = true`) and carries the company/city/search name in the
--      payload, so the alert mailer can group a run's matches into ONE digest
--      per person instead of one email per vacancy. A companion matcher does
--      the same for followed companies (0062), so both things a seeker can
--      save — a search and a company — alert the same way.
--   4. Lifecycle — two triggers on auth.users pg_net-POST to the
--      `lifecycle-email` function so a new account gets a real welcome email
--      the moment it exists (confirmations off) or the moment its address is
--      confirmed (confirmations on). Exactly one welcome per account.
--   5. Marketing — `admin_broadcast` gains `p_send_email`, so a broadcast can
--      also land in the inbox of everyone who hasn't opted out of marketing.
--
-- Production must add one row to private.app_secrets (0040), next to the
-- notify_dispatch pair:
--   ('lifecycle_email_url', 'https://<ref>.functions.supabase.co/lifecycle-email')
-- Unset (local `supabase db reset`, CI) → the trigger no-ops, like 0026's.

-- ---------------------------------------------------------------------------
-- 1. Preferences
-- ---------------------------------------------------------------------------
alter table public.notification_settings
  add column if not exists email_reviews   boolean not null default false,
  add column if not exists email_marketing boolean not null default true,
  -- Volatile default → Postgres rewrites the table and mints a distinct token
  -- per existing row (no manual backfill needed).
  add column if not exists unsubscribe_token uuid not null default gen_random_uuid();

create unique index if not exists notification_settings_unsubscribe_token_key
  on public.notification_settings (unsubscribe_token);

-- Job alerts are the product's core promise ("save a search, hear about new
-- vacancies"), so email defaults ON for them. The one-time backfill opts
-- existing rows in: this ships pre-launch, where every row is a test/early
-- account, and each mail carries the unsubscribe link added above.
alter table public.notification_settings
  alter column email_job_match set default true;
update public.notification_settings set email_job_match = true
 where email_job_match = false;

-- ---------------------------------------------------------------------------
-- 2. Send log
-- ---------------------------------------------------------------------------
create table if not exists public.email_deliveries (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid references public.profiles(id) on delete set null,
  to_email     text not null,
  kind         text not null,
  locale       text not null default 'uz',
  subject      text not null,
  status       text not null check (status in ('sent', 'failed', 'skipped')),
  provider_id  text,
  error        text,
  -- Set for sends that must happen at most once (e.g. 'welcome:<uid>').
  dedupe_key   text,
  created_at   timestamptz not null default now()
);

create index if not exists email_deliveries_recipient_idx
  on public.email_deliveries (recipient_id, created_at desc);
create index if not exists email_deliveries_kind_idx
  on public.email_deliveries (kind, created_at desc);
-- Only a *successful* send claims the key, so a failed attempt can be retried.
create unique index if not exists email_deliveries_dedupe_key
  on public.email_deliveries (dedupe_key)
  where dedupe_key is not null and status = 'sent';

alter table public.email_deliveries enable row level security;
-- Readable by the person it was sent to (a "what did you send me?" view);
-- written only by the service role (edge functions), which bypasses RLS.
drop policy if exists "email_deliveries own select" on public.email_deliveries;
create policy "email_deliveries own select"
  on public.email_deliveries for select to authenticated
  using (auth.uid() = recipient_id);

-- ---------------------------------------------------------------------------
-- 3. Token-scoped preference writes (the unsubscribe link)
-- ---------------------------------------------------------------------------
-- Maps an email's `scope` to the columns it switches. 'all' silences every
-- category; the caller can also re-enable (p_enabled = true) so the landing
-- page can offer "undo" for a mis-click.
create or replace function public.set_email_pref_by_token(
  p_token   uuid,
  p_scope   text default 'all',
  p_enabled boolean default false
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_enabled boolean := coalesce(p_enabled, false);
  v_scope   text    := coalesce(nullif(trim(p_scope), ''), 'all');
  v_row     public.notification_settings;
begin
  if p_token is null then
    raise exception 'invalid token' using errcode = '22023';
  end if;
  if v_scope not in ('all', 'job_match', 'marketing', 'messages', 'application', 'reviews') then
    raise exception 'invalid scope' using errcode = '22023';
  end if;

  update public.notification_settings s
     set email_job_match   = case when v_scope in ('all', 'job_match')   then v_enabled else s.email_job_match end,
         email_marketing   = case when v_scope in ('all', 'marketing')   then v_enabled else s.email_marketing end,
         email_messages    = case when v_scope in ('all', 'messages')    then v_enabled else s.email_messages end,
         email_application = case when v_scope in ('all', 'application') then v_enabled else s.email_application end,
         email_reviews     = case when v_scope in ('all', 'reviews')     then v_enabled else s.email_reviews end
   where s.unsubscribe_token = p_token
  returning s.* into v_row;

  if v_row.profile_id is null then
    raise exception 'unknown token' using errcode = 'P0002';
  end if;

  -- Never echo the address or the profile id back: the token travels in a
  -- URL, so the response has to be useless to anyone who intercepts it.
  return jsonb_build_object(
    'scope',             v_scope,
    'enabled',           v_enabled,
    'email_job_match',   v_row.email_job_match,
    'email_marketing',   v_row.email_marketing,
    'email_messages',    v_row.email_messages,
    'email_application', v_row.email_application,
    'email_reviews',     v_row.email_reviews
  );
end;
$$;

-- Read-only companion, so the landing page can render the current state
-- without changing anything (mail scanners follow links; a GET must not
-- unsubscribe anyone).
create or replace function public.email_prefs_by_token(p_token uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
           'email_job_match',   s.email_job_match,
           'email_marketing',   s.email_marketing,
           'email_messages',    s.email_messages,
           'email_application', s.email_application,
           'email_reviews',     s.email_reviews
         )
    from public.notification_settings s
   where s.unsubscribe_token = p_token;
$$;

revoke all on function public.set_email_pref_by_token(uuid, text, boolean) from public;
revoke all on function public.email_prefs_by_token(uuid) from public;
-- The recipient of an email is, by definition, not signed in when they click
-- "unsubscribe" — the token itself is the authorization.
grant execute on function public.set_email_pref_by_token(uuid, text, boolean) to anon, authenticated;
grant execute on function public.email_prefs_by_token(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Alerts: richer payloads + followed-company matching
-- ---------------------------------------------------------------------------
-- Same matcher as 0036, with the payload the mailer needs: `alert` marks the
-- row as digest-owned (notify-dispatch must not also send a single email for
-- it), and company/city/search carry the digest's copy without a second query.
create or replace function public.run_saved_search_alerts()
  returns integer
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_now   timestamptz := now();
  v_count integer;
begin
  perform pg_advisory_xact_lock(hashtext('run_saved_search_alerts'));

  with matches as (
    select
      ss.id         as ss_id,
      ss.name       as ss_name,
      ss.profile_id as profile_id,
      j.id          as job_id,
      j.title       as job_title,
      c.name        as company_name,
      j.city        as city
    from public.saved_searches ss
    join public.jobs j
      on j.status = 'open'
     and (j.expires_at is null or j.expires_at > v_now)
     and j.posted_at > ss.last_alerted_at
     and j.posted_at <= v_now
    join public.companies c on c.id = j.company_id
    left join public.job_categories cat on cat.id = j.category_id
    where (ss.city is null or ss.city = '' or j.city = ss.city)
      and (
        ss.keywords is null or ss.keywords = ''
        or j.title  ilike '%' || ss.keywords || '%'
        or c.name   ilike '%' || ss.keywords || '%'
        or cat.name ilike '%' || ss.keywords || '%'
      )
  ),
  inserted as (
    insert into public.notifications (recipient_id, type, title, body, data)
    select
      m.profile_id,
      'job_match',
      m.job_title,
      concat_ws(' · ', m.company_name, nullif(m.city, '')),
      jsonb_build_object(
        'job_id',          m.job_id,
        'saved_search_id', m.ss_id,
        'alert',           true,
        'source',          'saved_search',
        'search_name',     m.ss_name,
        'company',         m.company_name,
        'city',            m.city
      )
    from matches m
    returning 1
  )
  select count(*) into v_count from inserted;

  update public.saved_searches
     set last_alerted_at = v_now
   where last_alerted_at < v_now;

  return v_count;
end;
$$;

revoke all on function public.run_saved_search_alerts() from public;
grant execute on function public.run_saved_search_alerts() to service_role;

-- A seeker can save two things: a search (0035) and a company (0062). Only the
-- first alerted. This is the second: when a company you follow posts, you hear
-- about it — same notification type, same digest, same watermark discipline.
alter table public.company_follows
  add column if not exists last_alerted_at timestamptz not null default now();

create or replace function public.run_company_follow_alerts()
  returns integer
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_now   timestamptz := now();
  v_count integer;
begin
  perform pg_advisory_xact_lock(hashtext('run_company_follow_alerts'));

  with matches as (
    select
      f.profile_id as profile_id,
      j.id         as job_id,
      j.title      as job_title,
      c.id         as company_id,
      c.name       as company_name,
      j.city       as city
    from public.company_follows f
    join public.companies c on c.id = f.company_id
    join public.jobs j
      on j.company_id = f.company_id
     and j.status = 'open'
     and (j.expires_at is null or j.expires_at > v_now)
     and j.posted_at > f.last_alerted_at
     and j.posted_at <= v_now
    -- An employer following their own company shouldn't be told about their
    -- own posting.
    where j.posted_by is distinct from f.profile_id
  ),
  inserted as (
    insert into public.notifications (recipient_id, type, title, body, data)
    select
      m.profile_id,
      'job_match',
      m.job_title,
      concat_ws(' · ', m.company_name, nullif(m.city, '')),
      jsonb_build_object(
        'job_id',     m.job_id,
        'company_id', m.company_id,
        'alert',      true,
        'source',     'company_follow',
        'company',    m.company_name,
        'city',       m.city
      )
    from matches m
    returning 1
  )
  select count(*) into v_count from inserted;

  update public.company_follows
     set last_alerted_at = v_now
   where last_alerted_at < v_now;

  return v_count;
end;
$$;

revoke all on function public.run_company_follow_alerts() from public;
grant execute on function public.run_company_follow_alerts() to service_role;

-- The alert mailer batches a run's matches into one digest per person, so it
-- needs to remember which rows it has already covered. `data.emailed` is that
-- watermark, per notification: set once the digest for it has been sent (or
-- deliberately skipped), never re-sent afterwards. jsonb concat isn't
-- expressible through PostgREST, hence this definer helper.
create or replace function public.mark_alert_notifications_emailed(p_ids uuid[])
returns integer
language sql
security definer
set search_path = public
as $$
  with updated as (
    update public.notifications
       set data = data || jsonb_build_object('emailed', true)
     where id = any(p_ids)
    returning 1
  )
  select count(*)::int from updated;
$$;

revoke all on function public.mark_alert_notifications_emailed(uuid[]) from public;
grant execute on function public.mark_alert_notifications_emailed(uuid[]) to service_role;

-- ---------------------------------------------------------------------------
-- 5. Lifecycle email (welcome / address confirmed)
-- ---------------------------------------------------------------------------
create or replace function public.dispatch_lifecycle_email()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  -- Same source as notify_dispatch() (0040): a managed project's `postgres`
  -- role cannot `alter database … set`, so the URL/secret live in the locked
  -- private.app_secrets table, with the GUC kept as a local/self-hosted
  -- fallback.
  v_url    text := coalesce(
    (select value from private.app_secrets where name = 'lifecycle_email_url'),
    current_setting('app.lifecycle_email_url', true));
  v_secret text := coalesce(
    (select value from private.app_secrets where name = 'edge_shared_secret'),
    current_setting('app.edge_shared_secret', true));
begin
  if v_url is null or v_url = '' then
    return new;   -- not configured (local/CI) -> no-op
  end if;
  if new.email is null or new.email = '' then
    return new;   -- phone/Telegram-only account: nothing to write to
  end if;

  perform net.http_post(
    url     := v_url,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-edge-secret', coalesce(v_secret, '')),
    body    := jsonb_build_object(
                 'kind',    'welcome',
                 'user_id', new.id,
                 'email',   new.email,
                 -- 'signup' when confirmations are off (the account is usable
                 -- immediately), 'confirmed' when the address was just
                 -- verified. The mail acknowledges the difference in one line.
                 'trigger', case when tg_op = 'UPDATE' then 'confirmed' else 'signup' end)
  );
  return new;
end;
$$;

-- Confirmations OFF: the row is born confirmed → welcome now.
drop trigger if exists on_auth_user_welcome_email on auth.users;
create trigger on_auth_user_welcome_email
  after insert on auth.users
  for each row
  when (new.email_confirmed_at is not null)
  execute function public.dispatch_lifecycle_email();

-- Confirmations ON: Supabase Auth sends the branded confirmation mail; the
-- welcome follows the moment the address is verified. The WHEN clause makes
-- this fire once per account, so the two triggers can never both send.
drop trigger if exists on_auth_user_confirmed_email on auth.users;
create trigger on_auth_user_confirmed_email
  after update of email_confirmed_at on auth.users
  for each row
  when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  execute function public.dispatch_lifecycle_email();

-- ---------------------------------------------------------------------------
-- 6. Marketing broadcast: optional email fan-out
-- ---------------------------------------------------------------------------
-- The 4-arg version has to go before the 5-arg one exists, or a 4-argument
-- call becomes ambiguous (PostgREST resolves by name and would 300).
drop function if exists public.admin_broadcast(text, text, text, text);

create or replace function public.admin_broadcast(
  p_title text,
  p_body text,
  p_audience text default 'all',
  p_city text default null,
  p_send_email boolean default false
) returns int language plpgsql security definer set search_path = public as $$
declare
  v_cap   int := 5000;   -- max recipients per single broadcast
  v_count int;
  v_email boolean := coalesce(p_send_email, false);
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_audience not in ('all', 'seekers', 'employers') then
    raise exception 'invalid audience';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'title is required';
  end if;

  create temporary table _broadcast_targets on commit drop as
    select p.id
    from public.profiles p
    where p.suspended_at is null
      and (
        p_audience = 'all'
        or (p_audience = 'seekers' and p.role = 'job_seeker')
        or (p_audience = 'employers' and p.role = 'employer')
      )
      and (p_city is null or p_city = '' or p.city = p_city);

  select count(*) into v_count from _broadcast_targets;
  if v_count = 0 then
    raise exception 'no recipients match this audience';
  end if;
  if v_count > v_cap then
    raise exception
      'audience too large (% recipients, max %) — narrow by city or split the send',
      v_count, v_cap;
  end if;

  -- `email` in the payload is what opts this broadcast into the mail channel;
  -- notify-dispatch then still honors each recipient's email_marketing switch.
  insert into public.notifications (recipient_id, type, title, body, data)
    select t.id, 'system', trim(p_title), nullif(trim(coalesce(p_body, '')), ''),
           jsonb_build_object(
             'broadcast', true,
             'audience',  p_audience,
             'email',     v_email
           )
    from _broadcast_targets t;

  perform public.admin_audit(
    'broadcast.send', 'notifications', null,
    jsonb_build_object(
      'audience', p_audience, 'city', p_city,
      'count', v_count, 'email', v_email
    )
  );

  return v_count;
end;
$$;
grant execute on function public.admin_broadcast(text, text, text, text, boolean) to authenticated;
