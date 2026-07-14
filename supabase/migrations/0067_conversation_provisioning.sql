-- 0065_conversation_provisioning.sql
-- Employer → candidate messaging needs a REAL conversation row before the chat
-- can open (no synthetic ids). This adds a single provisioning entry point that
-- either returns the existing 1:1 DM between the caller and the other party or
-- atomically creates one (conversation + both participant rows).
--
-- Mirrors start_direct_conversation() (migration 0010) but hardens the match to
-- an EXACT participant set {auth.uid(), p_other} and validates that p_other is a
-- real profile. SECURITY DEFINER so it can insert the participant rows that the
-- post-0027 RLS deliberately forbids clients from inserting themselves.
--
-- Idempotent (create or replace). Not destructive; safe to re-run.

create or replace function public.get_or_create_direct_conversation(p_other uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_me uuid := auth.uid();
  v_id uuid;
begin
  if v_me is null then
    raise exception 'not authenticated';
  end if;
  if p_other is null or p_other = v_me then
    raise exception 'cannot start a conversation with yourself';
  end if;
  if not exists (select 1 from public.profiles p where p.id = p_other) then
    raise exception 'profile % does not exist', p_other;
  end if;

  -- Reuse the DIRECT conversation whose participant set is EXACTLY {me, other}:
  -- both parties present and no third member.
  select c.id into v_id
  from public.conversations c
  where c.type = 'direct'
    and exists (
      select 1 from public.conversation_participants cp
      where cp.conversation_id = c.id and cp.profile_id = v_me
    )
    and exists (
      select 1 from public.conversation_participants cp
      where cp.conversation_id = c.id and cp.profile_id = p_other
    )
    and (
      select count(*) from public.conversation_participants cp
      where cp.conversation_id = c.id
    ) = 2
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  insert into public.conversations (type) values ('direct') returning id into v_id;
  insert into public.conversation_participants (conversation_id, profile_id)
    values (v_id, v_me), (v_id, p_other);
  return v_id;
end;
$$;

grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;
