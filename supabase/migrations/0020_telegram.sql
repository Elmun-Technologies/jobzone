-- 0020_telegram.sql
-- Telegram notify-bridge: link a profile to a Telegram chat so notifications can
-- also be delivered there. The link is created by the telegram-webhook edge
-- function (service role) after a one-time-token /start handshake. Actual
-- message delivery is sent by the bot and is a no-op until TELEGRAM_BOT_TOKEN
-- exists.

create table if not exists public.telegram_links (
  profile_id       uuid primary key references public.profiles(id) on delete cascade,
  telegram_chat_id text not null unique,
  username         text,
  linked_at        timestamptz not null default now()
);
alter table public.telegram_links enable row level security;
drop policy if exists "telegram_links select own" on public.telegram_links;
create policy "telegram_links select own"
  on public.telegram_links for select to authenticated
  using (profile_id = auth.uid());
drop policy if exists "telegram_links delete own" on public.telegram_links;
create policy "telegram_links delete own"
  on public.telegram_links for delete to authenticated
  using (profile_id = auth.uid());
-- Inserts happen via the webhook (service role) after the /start handshake.

-- One-time link tokens: the app mints a token, the user sends it to the bot,
-- and the webhook resolves it to the profile and creates the link.
create table if not exists public.telegram_link_tokens (
  token      text primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '15 minutes')
);
alter table public.telegram_link_tokens enable row level security;
-- No client policies: minted via the RPC (security definer), read by the
-- webhook (service role).

create or replace function public.start_telegram_link()
returns text language plpgsql security definer set search_path = public as $$
declare v_token text;
begin
  if auth.uid() is null then raise exception 'auth required'; end if;
  v_token := encode(extensions.gen_random_bytes(8), 'hex');
  insert into public.telegram_link_tokens (token, profile_id)
  values (v_token, auth.uid());
  return v_token;
end;
$$;
grant execute on function public.start_telegram_link() to authenticated;
