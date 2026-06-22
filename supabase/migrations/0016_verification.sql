-- 0016_verification.sql
-- Two-sided trust: verified employers (legal entity / licensed agency) and
-- verified workers (+ phone). Verification is admin-granted; a user can NEVER
-- self-verify — guarded by the same txn-flag pattern as the boost columns
-- (0011_monetization.sql `guard_job_boost`).

-- ---------------------------------------------------------------------------
-- Columns (audit who/when/how). `companies.is_verified` already exists.
-- ---------------------------------------------------------------------------
alter table public.companies
  add column if not exists verified_at         timestamptz,
  add column if not exists verified_by         uuid references public.profiles(id) on delete set null,
  add column if not exists verification_method text
    check (verification_method is null
           or verification_method in ('legal_entity','licensed_agency'));

alter table public.profiles
  add column if not exists phone_verified_at          timestamptz,
  add column if not exists worker_verified_at         timestamptz,
  add column if not exists worker_verified_by         uuid references public.profiles(id) on delete set null,
  add column if not exists worker_verification_method text
    check (worker_verification_method is null
           or worker_verification_method in ('id_document','manual'));

-- ---------------------------------------------------------------------------
-- Admin check: app_metadata.role is server-only (a user cannot set it), so
-- this is a safe privilege gate.
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

-- ---------------------------------------------------------------------------
-- Guards: clients may never write the verification columns directly. The
-- legitimate setters (admin RPCs / confirm_phone) raise a txn-local flag.
-- ---------------------------------------------------------------------------
create or replace function public.guard_company_verification()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.granting_verification', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.is_verified := false;
    new.verified_at := null;
    new.verified_by := null;
    new.verification_method := null;
  else
    new.is_verified := old.is_verified;
    new.verified_at := old.verified_at;
    new.verified_by := old.verified_by;
    new.verification_method := old.verification_method;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_company_verification on public.companies;
create trigger trg_guard_company_verification
  before insert or update on public.companies
  for each row execute function public.guard_company_verification();

create or replace function public.guard_profile_verification()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.granting_verification', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.phone_verified_at := null;
    new.worker_verified_at := null;
    new.worker_verified_by := null;
    new.worker_verification_method := null;
  else
    new.phone_verified_at := old.phone_verified_at;
    new.worker_verified_at := old.worker_verified_at;
    new.worker_verified_by := old.worker_verified_by;
    new.worker_verification_method := old.worker_verification_method;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_profile_verification on public.profiles;
create trigger trg_guard_profile_verification
  before insert or update on public.profiles
  for each row execute function public.guard_profile_verification();

-- ---------------------------------------------------------------------------
-- Grant RPCs (admin only). Raise the flag, write the columns, audit the actor.
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_company_verification(
  p_company uuid, p_method text
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.granting_verification', '1', true);
  update public.companies
     set is_verified = true, verified_at = now(),
         verified_by = auth.uid(), verification_method = p_method
   where id = p_company;
  perform set_config('app.granting_verification', '0', true);
end;
$$;
grant execute on function public.admin_set_company_verification(uuid, text) to authenticated;

create or replace function public.admin_set_worker_verification(
  p_profile uuid, p_method text
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.granting_verification', '1', true);
  update public.profiles
     set worker_verified_at = now(), worker_verified_by = auth.uid(),
         worker_verification_method = p_method
   where id = p_profile;
  perform set_config('app.granting_verification', '0', true);
end;
$$;
grant execute on function public.admin_set_worker_verification(uuid, text) to authenticated;

-- Self-serve phone verification — only if Supabase Auth has confirmed the phone
-- (no SMS pipeline is built here; this trusts auth.users.phone_confirmed_at).
create or replace function public.confirm_phone()
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from auth.users
    where id = auth.uid() and phone_confirmed_at is not null
  ) then
    raise exception 'phone not confirmed';
  end if;
  perform set_config('app.granting_verification', '1', true);
  update public.profiles set phone_verified_at = now() where id = auth.uid();
  perform set_config('app.granting_verification', '0', true);
end;
$$;
grant execute on function public.confirm_phone() to authenticated;

-- ---------------------------------------------------------------------------
-- Expose verification booleans on the public projection (no timestamps leaked).
-- ---------------------------------------------------------------------------
create or replace view public.profiles_public
  with (security_invoker = true) as
  select id, full_name, headline, avatar_url, cover_url, city, country,
         is_open_to_work,
         (phone_verified_at is not null)  as phone_verified,
         (worker_verified_at is not null) as worker_verified
  from public.profiles;
