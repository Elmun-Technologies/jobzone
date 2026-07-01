-- 0038_private_secrets.sql
-- Server-side secrets live in a locked table, not database-level GUCs.
-- Discovered at go-live: Supabase's managed `postgres` role is not allowed to
-- run `alter database … set` (ERROR 42501: permission denied to set
-- parameter), so the current_setting('app.…') pattern used by 0026/0037 can't
-- be configured from the dashboard SQL editor. `private.app_secrets` is
-- readable only through security-definer functions (owner: postgres);
-- anon/authenticated get no grants on the schema or the table.
--
-- Operator setup (SQL editor — secret values never live in the repo):
--   insert into private.app_secrets (name, value) values
--     ('telegram_gateway_token', '<gateway.telegram.org token>')
--   on conflict (name) do update set value = excluded.value;
-- Optional, to enable the notification fan-out (0026):
--     ('notify_dispatch_url', 'https://<ref>.functions.supabase.co/notify-dispatch'),
--     ('edge_shared_secret',  '<same value as the EDGE_SHARED_SECRET fn secret>')

create schema if not exists private;
create table if not exists private.app_secrets (
  name  text primary key,
  value text not null
);
revoke all on schema private from public, anon, authenticated;
revoke all on private.app_secrets from public, anon, authenticated;

-- Telegram-OTP Send-SMS hook (0037), now reading the token from the table.
create or replace function public.send_sms_telegram(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
  v_phone text := event->'user'->>'phone';
  v_otp   text := event->'sms'->>'otp';
begin
  select value into v_token
    from private.app_secrets where name = 'telegram_gateway_token';

  if v_token is null or v_token = '' then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 500,
      'message', 'telegram_gateway_token is not configured'));
  end if;
  if v_phone is null or v_otp is null then
    return jsonb_build_object('error', jsonb_build_object(
      'http_code', 400,
      'message', 'missing phone or otp in hook payload'));
  end if;

  if left(v_phone, 1) <> '+' then
    v_phone := '+' || v_phone;
  end if;

  perform net.http_post(
    url     := 'https://gateway.telegram.org/sendVerificationMessage',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'Authorization', 'Bearer ' || v_token),
    body    := jsonb_build_object('phone_number', v_phone, 'code', v_otp)
  );

  return '{}'::jsonb;
end;
$$;

-- Notification fan-out (0026): its `alter database … set` config hits the same
-- 42501 on managed projects, so read the table first and keep current_setting
-- as a fallback where the GUC route does work. Body otherwise identical.
create or replace function public.notify_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url    text := coalesce(
    (select value from private.app_secrets where name = 'notify_dispatch_url'),
    current_setting('app.notify_dispatch_url', true));
  v_secret text := coalesce(
    (select value from private.app_secrets where name = 'edge_shared_secret'),
    current_setting('app.edge_shared_secret', true));
begin
  if v_url is null or v_url = '' then
    return new;   -- not configured (local/CI) -> no-op
  end if;

  perform net.http_post(
    url     := v_url,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-edge-secret', coalesce(v_secret, '')),
    body    := jsonb_build_object(
                 'type',   tg_op,
                 'table',  tg_table_name,
                 'record', to_jsonb(new))
  );
  return new;
end;
$$;
