-- 0010_security_hardening.sql
-- RLS hardening from the project audit. Idempotent (safe to re-run).

-- ---------------------------------------------------------------------------
-- 1) job_skills had NO row-level security → it was world-writable via the API.
--    Enable RLS: anyone may read; only the owner of the job may write.
-- ---------------------------------------------------------------------------
alter table public.job_skills enable row level security;

drop policy if exists "job_skills readable by all" on public.job_skills;
create policy "job_skills readable by all"
  on public.job_skills for select using (true);

drop policy if exists "job_skills write by job owner" on public.job_skills;
create policy "job_skills write by job owner"
  on public.job_skills for all to authenticated
  using (public.is_job_owner(job_id))
  with check (public.is_job_owner(job_id));

-- ---------------------------------------------------------------------------
-- 2) conversation_participants: the old "self-manage" policy let ANY existing
--    participant add/remove ARBITRARY users (the `or is_conversation_participant`
--    in WITH CHECK). Restrict writes so a user can only manage their OWN row.
--    Adding the other party to a DM now goes through start_direct_conversation().
-- ---------------------------------------------------------------------------
drop policy if exists "participants self-manage" on public.conversation_participants;

create policy "participants insert self"
  on public.conversation_participants for insert to authenticated
  with check (profile_id = auth.uid());

create policy "participants update self"
  on public.conversation_participants for update to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy "participants delete self"
  on public.conversation_participants for delete to authenticated
  using (profile_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 3) conversations: drop the `with check (true)` insert policy. Conversations
--    are now created only via start_direct_conversation() (security definer),
--    which atomically adds both participants — no orphaned/hijackable shells.
-- ---------------------------------------------------------------------------
drop policy if exists "conversations insert by authenticated" on public.conversations;

create or replace function public.start_direct_conversation(other_profile_id uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  if other_profile_id = auth.uid() then
    raise exception 'cannot start a conversation with yourself';
  end if;

  -- Reuse an existing 1:1 conversation between these two users if present.
  select cp.conversation_id into v_id
  from public.conversation_participants cp
  join public.conversation_participants cp2
    on cp2.conversation_id = cp.conversation_id
  join public.conversations c on c.id = cp.conversation_id
  where c.type = 'direct'
    and cp.profile_id = auth.uid()
    and cp2.profile_id = other_profile_id
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  insert into public.conversations (type) values ('direct') returning id into v_id;
  insert into public.conversation_participants (conversation_id, profile_id)
    values (v_id, auth.uid()), (v_id, other_profile_id);
  return v_id;
end;
$$;

grant execute on function public.start_direct_conversation(uuid) to authenticated;
