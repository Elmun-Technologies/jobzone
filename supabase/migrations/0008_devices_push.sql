-- 0008_devices_push.sql
-- Phase 8: per-device push tokens (FCM). Targeted by the `push-dispatch`
-- Edge Function for remote notifications. Owner-scoped via RLS.

create table public.devices (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  fcm_token   text unique not null,
  platform    text not null default 'mobile' check (platform in ('mobile','web')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index on public.devices (profile_id);
create trigger trg_devices_updated_at before update on public.devices
  for each row execute function public.set_updated_at();

alter table public.devices enable row level security;
create policy "devices own"
  on public.devices for all to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
-- The service role (Edge Functions) bypasses RLS to read tokens for fan-out.
