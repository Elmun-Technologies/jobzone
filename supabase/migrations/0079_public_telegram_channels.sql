-- 0079_public_telegram_channels.sql
-- Let the public employer page show where a vacancy actually goes.
--
-- 0058 built the auto-posting pipeline (a vacancy that turns 'open' is pushed
-- to the Telegram channel for its category + region) but gave the table no
-- client policies at all: the mapping is readable only through the admin
-- panel's service-role key. So the platform's single strongest argument to an
-- employer — "your vacancy also reaches the channel for your trade in your
-- region" — was invisible to the employer.
--
-- This adds a read-only policy for ACTIVE channels. Nothing here is sensitive:
-- a channel is a public Telegram channel, and its chat id is either a public
-- @username or an opaque number that grants nobody anything (posting still
-- requires the bot token, which never leaves the edge function). Writes stay
-- admin-only through the definer RPCs from 0058 — this policy is SELECT only.

drop policy if exists "active telegram channels are public" on public.telegram_channels;
create policy "active telegram channels are public"
  on public.telegram_channels for select
  using (is_active = true);
