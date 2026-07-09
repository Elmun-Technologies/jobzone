-- 0057_admin_settings.sql
-- Platform settings: a small key/value store the technical team edits from the
-- panel to change platform-wide behavior without a code deploy. First concrete
-- setting is a site-wide announcement/maintenance banner. Values are
-- non-sensitive (they drive public UI), so the table is world-readable; only
-- admins may write, via the definer RPC.

create table if not exists public.platform_settings (
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

alter table public.platform_settings enable row level security;

drop policy if exists "platform_settings readable by all" on public.platform_settings;
create policy "platform_settings readable by all"
  on public.platform_settings for select using (true);
-- No client write policy: writes go through admin_set_setting only.

-- Seed the announcement banner (disabled by default).
insert into public.platform_settings (key, value) values
  ('site_banner', jsonb_build_object('enabled', false, 'message', '', 'tone', 'info'))
on conflict (key) do nothing;

create or replace function public.admin_set_setting(p_key text, p_value jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if coalesce(trim(p_key), '') = '' then raise exception 'key is required'; end if;

  insert into public.platform_settings (key, value, updated_at, updated_by)
    values (p_key, coalesce(p_value, '{}'::jsonb), now(), auth.uid())
  on conflict (key) do update
    set value = excluded.value, updated_at = now(), updated_by = auth.uid();

  perform public.admin_audit(
    'setting.update', 'platform_settings', p_key,
    jsonb_build_object('value', p_value)
  );
end;
$$;
grant execute on function public.admin_set_setting(text, jsonb) to authenticated;
