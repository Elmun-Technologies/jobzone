-- 0026_notify_dispatch.sql
-- Fan in-app notifications out to external channels. One AFTER-INSERT trigger on
-- `notifications` pg_net-POSTs each new row to the `notify-dispatch` Edge
-- Function, which respects `notification_settings` and delivers to the
-- recipient's linked Telegram chat (FCM is added in a later migration). The
-- in-app row already exists — this only mirrors it outward.
--
-- Production must set (DB settings or Supabase Vault):
--   app.notify_dispatch_url = 'https://<project-ref>.functions.supabase.co/notify-dispatch'
--   app.edge_shared_secret  = '<shared secret, also the function secret EDGE_SHARED_SECRET>'
--
-- When app.notify_dispatch_url is empty (local `supabase db reset`, CI) the
-- trigger no-ops safely so migrations always apply cleanly.

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url    text := current_setting('app.notify_dispatch_url', true);
  v_secret text := current_setting('app.edge_shared_secret', true);
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

drop trigger if exists trg_notify_dispatch on public.notifications;
create trigger trg_notify_dispatch
  after insert on public.notifications
  for each row execute function public.notify_dispatch();
