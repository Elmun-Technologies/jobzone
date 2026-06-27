-- 0027_security_pii_lockdown.sql
-- P0 security hardening from the project audit. Closes:
--   1. PII/location harvest: `profiles` and `profiles_public` exposed every
--      worker's exact lat/lng, desired pay, phone, email and bio to ANY
--      authenticated user.
--   2. contact_info (home address, telegram, socials) world-readable.
--   3. Applicant self-promotion to hired/offer via the status-history INSERT
--      policy and an unguarded applications UPDATE policy.
--   4. conversation_participants self-insert into ARBITRARY conversations.
--
-- Idempotent (drop policy if exists ... / create or replace).

-- ---------------------------------------------------------------------------
-- 1) profiles: lock direct reads to the owner. Cross-user display goes through
--    the column-safe `profiles_public` view (recreated below as a definer view
--    so it can read all rows but only exposes non-sensitive columns).
-- ---------------------------------------------------------------------------
drop policy if exists "profiles selectable by authenticated" on public.profiles;
drop policy if exists "profiles select own" on public.profiles;
create policy "profiles select own"
  on public.profiles for select to authenticated
  using (auth.uid() = id);

-- Safe public projection. NO lat/lng, NO desired_pay, NO phone/email/bio.
-- security_invoker = false (definer) so it bypasses the owner-only base RLS and
-- can serve these safe columns for any profile; access is gated by the grants
-- below (authenticated only, never anon).
drop view if exists public.profiles_public;
create view public.profiles_public as
  select id, full_name, headline, avatar_url, cover_url, city, country,
         is_open_to_work,
         (phone_verified_at is not null)  as phone_verified,
         (worker_verified_at is not null) as worker_verified,
         availability
  from public.profiles;
revoke all on public.profiles_public from anon;
grant select on public.profiles_public to authenticated;

-- ---------------------------------------------------------------------------
-- 2) Applicant coordinates for the employer commute-distance / map feature,
--    exposed ONLY for applicants to a job the caller owns (is_job_owner).
--    Definer view + auth.uid()-scoped predicate = no cross-tenant leakage.
-- ---------------------------------------------------------------------------
create or replace view public.applicant_locations as
  select distinct a.applicant_id, p.lat, p.lng
  from public.applications a
  join public.profiles p on p.id = a.applicant_id
  where p.lat is not null and p.lng is not null
    and public.is_job_owner(a.job_id);
revoke all on public.applicant_locations from anon;
grant select on public.applicant_locations to authenticated;

-- ---------------------------------------------------------------------------
-- 3) contact_info: owner-only reads (was world-readable).
-- ---------------------------------------------------------------------------
drop policy if exists "contact_info selectable by authenticated" on public.contact_info;
drop policy if exists "contact_info select own" on public.contact_info;
create policy "contact_info select own"
  on public.contact_info for select to authenticated
  using (auth.uid() = profile_id);

-- ---------------------------------------------------------------------------
-- 4) Application status integrity: only the job owner may write status history
--    (the initial 'submitted' row is inserted by the SECURITY DEFINER
--    on_application_insert trigger, so applicants need no INSERT here), and only
--    the job owner may UPDATE an application. This removes both self-promotion
--    paths (history-INSERT and direct applications UPDATE).
-- ---------------------------------------------------------------------------
drop policy if exists "status history insert by applicant or owner" on public.application_status_history;
drop policy if exists "status history insert by job owner" on public.application_status_history;
create policy "status history insert by job owner"
  on public.application_status_history for insert to authenticated
  with check (exists (
    select 1 from public.applications a
    where a.id = application_id and public.is_job_owner(a.job_id)
  ));

drop policy if exists "applications update by applicant or owner" on public.applications;
drop policy if exists "applications update by job owner" on public.applications;
create policy "applications update by job owner"
  on public.applications for update to authenticated
  using (public.is_job_owner(job_id))
  with check (public.is_job_owner(job_id));

-- ---------------------------------------------------------------------------
-- 5) conversation_participants: remove the self-insert policy. It only
--    constrained WHO (self) not WHICH conversation, so any user could join an
--    arbitrary conversation and read its history. Membership is created solely
--    by start_direct_conversation() (SECURITY DEFINER, migration 0010). The
--    self-update (last_read_at) and self-delete policies remain.
-- ---------------------------------------------------------------------------
drop policy if exists "participants insert self" on public.conversation_participants;
