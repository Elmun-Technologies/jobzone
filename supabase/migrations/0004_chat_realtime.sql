-- 0004_chat_realtime.sql
-- Real-time direct messaging. Calls are UI-only for now (a `calls` table is added
-- in a later phase when WebRTC/Agora is wired up).

create table public.conversations (
  id              uuid primary key default gen_random_uuid(),
  type            text not null default 'direct' check (type in ('direct','group')),
  created_at      timestamptz not null default now(),
  last_message_id uuid,
  last_message_at timestamptz
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  profile_id      uuid not null references public.profiles(id) on delete cascade,
  role            text not null default 'member',
  last_read_at    timestamptz,
  joined_at       timestamptz not null default now(),
  primary key (conversation_id, profile_id)
);
create index on public.conversation_participants (profile_id);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references public.profiles(id) on delete cascade,
  content         text,
  type            text not null default 'text'
                   check (type in ('text','image','file','system','call_event')),
  attachment_url  text,
  created_at      timestamptz not null default now(),
  edited_at       timestamptz,
  deleted_at      timestamptz
);
create index on public.messages (conversation_id, created_at);

alter table public.conversations             add constraint conversations_last_message_fkey
  foreign key (last_message_id) references public.messages(id) on delete set null;

-- ---------------------------------------------------------------------------
-- RLS — participant-scoped. SECURITY DEFINER helper avoids recursive policy eval.
-- ---------------------------------------------------------------------------
create or replace function public.is_conversation_participant(p_conversation_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = p_conversation_id and cp.profile_id = auth.uid()
  );
$$;

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

create policy "conversations visible to participants"
  on public.conversations for select to authenticated
  using (public.is_conversation_participant(id));
create policy "conversations insert by authenticated"
  on public.conversations for insert to authenticated with check (true);

create policy "participants visible to members"
  on public.conversation_participants for select to authenticated
  using (public.is_conversation_participant(conversation_id));
create policy "participants self-manage"
  on public.conversation_participants for all to authenticated
  using (profile_id = auth.uid() or public.is_conversation_participant(conversation_id))
  with check (profile_id = auth.uid() or public.is_conversation_participant(conversation_id));

create policy "messages visible to participants"
  on public.messages for select to authenticated
  using (public.is_conversation_participant(conversation_id));
create policy "messages insert by sender participant"
  on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and public.is_conversation_participant(conversation_id));
create policy "messages update own"
  on public.messages for update to authenticated
  using (sender_id = auth.uid()) with check (sender_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Maintain conversations.last_message_* on new message
-- ---------------------------------------------------------------------------
create or replace function public.on_message_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.conversations
    set last_message_id = new.id, last_message_at = new.created_at
    where id = new.conversation_id;
  return new;
end;
$$;
create trigger trg_message_insert after insert on public.messages
  for each row execute function public.on_message_insert();

-- ---------------------------------------------------------------------------
-- Realtime: expose messages to Postgres Changes (filtered client-side by
-- conversation_id; RLS still applies). Migrate to Broadcast-from-DB at scale.
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.messages;
    alter publication supabase_realtime add table public.conversations;
  end if;
end $$;
