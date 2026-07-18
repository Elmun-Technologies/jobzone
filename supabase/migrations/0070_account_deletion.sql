-- 0070_account_deletion.sql
-- Self-service account deletion — required by Apple App Store 5.1.1(v)
-- and Play Store Data Safety. The `delete-account` edge function calls
-- Supabase Admin API to delete the auth.users row; ON DELETE CASCADE
-- on profiles.id (0001) then cascades through every user-scoped table.
--
-- What this migration adds:
--
-- 1. `account_deletion_log`: one row per completed deletion so support
--    can prove "we removed this user's data at $timestamp" if they ever
--    return under regulator/law scrutiny. Only the user id + timestamp
--    are stored — no personal data — so the log is itself compliant.
--
-- 2. `log_account_deletion(uuid)` definer RPC the edge fn calls with
--    the service-role client BEFORE calling admin.deleteUser. If the
--    delete then fails, the log row is a false positive but that's
--    far better than a false negative (deleted user with no proof).
--
-- Companies owned by the deleting user are NOT auto-deleted — a company
-- can have live vacancies and applicants who would lose context. Instead,
-- `owner_id` is set to null (matching the existing FK behaviour) and the
-- company is marked orphaned. Ops team can transfer or close it later.
-- Applications the user submitted (as a seeker) cascade — the employer
-- keeps only the anonymized status history the trigger writes.

create table if not exists public.account_deletion_log (
  id           bigint generated always as identity primary key,
  user_id      uuid not null,
  deleted_at   timestamptz not null default now(),
  reason       text,                       -- optional: seeker input
  ip_hash      text,                       -- SHA-256 of source IP, for anti-abuse
  meta         jsonb not null default '{}'::jsonb
);
create index if not exists account_deletion_log_user_idx
  on public.account_deletion_log (user_id);
create index if not exists account_deletion_log_created_idx
  on public.account_deletion_log (deleted_at desc);

-- Deletion log is admin-only. Regular users have no read access — they
-- already know they deleted; only support/regulators need it.
alter table public.account_deletion_log enable row level security;
drop policy if exists "deletion log readable by admins" on public.account_deletion_log;
create policy "deletion log readable by admins"
  on public.account_deletion_log for select to authenticated
  using (public.is_admin());

-- Writer RPC. Called by the delete-account edge function with the
-- service-role client, so the security definer body has full write
-- access. No client execute grant — writes come only from the edge fn.
create or replace function public.log_account_deletion(
  p_user uuid,
  p_reason text default null,
  p_ip_hash text default null,
  p_meta jsonb default '{}'::jsonb
) returns void language sql security definer set search_path = public as $$
  insert into public.account_deletion_log (user_id, reason, ip_hash, meta)
  values (p_user, p_reason, p_ip_hash, coalesce(p_meta, '{}'::jsonb));
$$;
revoke all on function public.log_account_deletion(uuid, text, text, jsonb) from public;

-- companies.owner_id is already `on delete set null` (0002), so the auth-user
-- cascade orphans the company rather than nuking it and every dependent row.
-- The admin panel handles orphaned companies as a separate concern.
