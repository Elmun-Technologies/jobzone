-- 0073: two residual RLS gaps found in the pre-scale security audit. Both are
-- own-account-only (no cross-tenant write), which is why they survived earlier
-- passes — closed here as defense-in-depth before traffic grows.

-- 1. Applicant could forge their own application status at INSERT time.
-- The insert policy only checks `auth.uid() = applicant_id`, so a direct
-- PostgREST insert could set current_status='hired' (or shortlisted/offer/…);
-- the AFTER-insert trigger then seeds a matching status-history row, so the
-- employer's pipeline and the admin funnel show a candidate as already
-- hired/shortlisted without the employer ever acting. 0027 locked the UPDATE
-- and the status-history INSERT to the job owner but left the initial INSERT
-- open. A new application must always start 'submitted'; only the job owner
-- advances it afterward (via application_status_history). Clamp it in a
-- BEFORE-insert trigger so a forged value is normalized rather than rejected
-- (legit inserts already use the 'submitted' default, so they're unaffected).
create or replace function public.clamp_application_insert_status()
returns trigger language plpgsql security invoker
set search_path = public as $$
begin
  new.current_status := 'submitted';
  return new;
end;
$$;

drop trigger if exists trg_application_clamp_insert_status on public.applications;
create trigger trg_application_clamp_insert_status
  before insert on public.applications
  for each row execute function public.clamp_application_insert_status();

-- 2. A user could move their own message into a conversation they're not in.
-- The `messages update own` WITH CHECK constrained only sender_id, not
-- conversation_id, so a sender could UPDATE their message and set
-- conversation_id to another (unguessable but RLS-protected) conversation,
-- injecting a message from a non-member. The INSERT policy already guards
-- participation; mirror it on UPDATE.
drop policy if exists "messages update own" on public.messages;
create policy "messages update own"
  on public.messages for update to authenticated
  using (sender_id = auth.uid())
  with check (
    sender_id = auth.uid()
    and public.is_conversation_participant(conversation_id)
  );
