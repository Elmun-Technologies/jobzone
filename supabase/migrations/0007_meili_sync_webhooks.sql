-- 0007_meili_sync_webhooks.sql
-- Sync `jobs` -> Meilisearch via pg_net webhooks calling the `meili-sync` Edge Function.
--
-- Production must set these (DB settings or Supabase Vault; or use the
-- Database Webhooks UI instead of these triggers):
--   app.meili_webhook_url  = 'https://<project-ref>.functions.supabase.co/meili-sync'
--   app.edge_shared_secret = '<shared secret, also set as the function secret EDGE_SHARED_SECRET>'
--
-- When app.meili_webhook_url is empty (local `supabase db reset`, CI) the
-- triggers no-op safely so migrations always apply cleanly.

create extension if not exists pg_net with schema extensions;

create or replace function public.meili_notify_change()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url    text := current_setting('app.meili_webhook_url', true);
  v_secret text := current_setting('app.edge_shared_secret', true);
begin
  if v_url is null or v_url = '' then
    return coalesce(new, old);   -- not configured (local/CI) -> no-op
  end if;

  perform net.http_post(
    url     := v_url,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-edge-secret', coalesce(v_secret, '')),
    body    := jsonb_build_object(
                 'type',       tg_op,
                 'table',      tg_table_name,
                 'record',     to_jsonb(new),
                 'old_record', to_jsonb(old))
  );
  return coalesce(new, old);
end;
$$;

create trigger trg_meili_sync_jobs
  after insert or update or delete on public.jobs
  for each row execute function public.meili_notify_change();

create trigger trg_meili_sync_companies
  after update on public.companies
  for each row execute function public.meili_notify_change();
