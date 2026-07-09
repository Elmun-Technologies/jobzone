-- 0054_admin_grants.sql
-- Admin user management: grant/revoke the app_metadata.role = 'admin' JWT
-- claim from the panel itself instead of a manual Supabase-dashboard trip.
-- Adds a denormalized profiles.is_admin mirror for the /admin/users list
-- (the JWT claim itself isn't queryable from SQL/REST) and extends the
-- existing profile guard trigger (0039) so a client can never flip it
-- directly — the same protection suspended_at already has.

alter table public.profiles
  add column if not exists is_admin boolean not null default false;

create or replace function public.guard_profile_moderation()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.moderating', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.suspended_at := null;
    new.suspended_by := null;
    new.suspended_reason := null;
    new.is_admin := false;
  else
    new.suspended_at := old.suspended_at;
    new.suspended_by := old.suspended_by;
    new.suspended_reason := old.suspended_reason;
    new.is_admin := old.is_admin;
  end if;
  return new;
end;
$$;
-- trg_guard_profile_moderation (0039) already calls this function by name on
-- every insert/update — nothing to recreate on the trigger itself.

-- ---------------------------------------------------------------------------
-- Mirrors a granted/revoked admin claim into profiles.is_admin for the users
-- list, and audits it. The actual JWT claim is set separately by the calling
-- server action via the Auth Admin API (service role — not reachable from
-- SQL). This RPC runs first in that flow and is also what authorizes it: it's
-- the only step that re-checks the caller is really an admin before anything
-- privileged happens.
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_profile_admin(p_profile uuid, p_is_admin boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.moderating', '1', true);
  update public.profiles set is_admin = p_is_admin where id = p_profile;
  if not found then raise exception 'profile not found'; end if;
  perform set_config('app.moderating', '0', true);
  perform public.admin_audit(
    'profile.set_admin', 'profiles', p_profile::text,
    jsonb_build_object('is_admin', p_is_admin)
  );
end;
$$;
grant execute on function public.admin_set_profile_admin(uuid, boolean) to authenticated;
