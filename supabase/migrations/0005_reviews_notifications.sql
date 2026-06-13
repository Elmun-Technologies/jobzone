-- 0005_reviews_notifications.sql
-- Company reviews (+ rating summary) and in-app notifications.

create table public.company_reviews (
  id                  uuid primary key default gen_random_uuid(),
  company_id          uuid not null references public.companies(id) on delete cascade,
  author_id           uuid not null references public.profiles(id) on delete cascade,
  rating              int not null check (rating between 1 and 5),
  title               text,
  body                text,
  pros                text,
  cons                text,
  is_current_employee boolean not null default false,
  job_title           text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (company_id, author_id)            -- one review per author per company
);
create index on public.company_reviews (company_id);
create trigger trg_company_reviews_updated_at before update on public.company_reviews
  for each row execute function public.set_updated_at();

alter table public.company_reviews enable row level security;
create policy "company_reviews readable by all"
  on public.company_reviews for select using (true);
create policy "company_reviews write own"
  on public.company_reviews for all to authenticated
  using (auth.uid() = author_id) with check (auth.uid() = author_id);

-- Aggregate used by company cards / Review tab header.
create or replace view public.company_rating_summary
  with (security_invoker = true) as
  select company_id,
         round(avg(rating)::numeric, 2) as avg_rating,
         count(*)                       as review_count
  from public.company_reviews
  group by company_id;

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  type         text not null
                check (type in ('application_update','message','job_match','review','system')),
  title        text not null,
  body         text,
  data         jsonb not null default '{}',
  is_read      boolean not null default false,
  created_at   timestamptz not null default now()
);
create index on public.notifications (recipient_id, created_at desc);

alter table public.notifications enable row level security;
create policy "notifications own select"
  on public.notifications for select to authenticated
  using (auth.uid() = recipient_id);
create policy "notifications own update"
  on public.notifications for update to authenticated
  using (auth.uid() = recipient_id) with check (auth.uid() = recipient_id);
-- Inserts are performed by SECURITY DEFINER triggers / service role only.

-- Notify the applicant when their application status changes.
create or replace function public.notify_application_status()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_applicant uuid;
begin
  select applicant_id into v_applicant from public.applications where id = new.application_id;
  if v_applicant is not null then
    insert into public.notifications (recipient_id, type, title, body, data)
    values (v_applicant, 'application_update',
            'Application update',
            format('Your application status changed to %s', new.status),
            jsonb_build_object('application_id', new.application_id, 'status', new.status));
  end if;
  return new;
end;
$$;
create trigger trg_notify_application_status after insert on public.application_status_history
  for each row execute function public.notify_application_status();

-- Notify the recipient on a new chat message.
create or replace function public.notify_new_message()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (recipient_id, type, title, body, data)
  select cp.profile_id, 'message', 'New message', left(coalesce(new.content,''), 120),
         jsonb_build_object('conversation_id', new.conversation_id, 'message_id', new.id)
  from public.conversation_participants cp
  where cp.conversation_id = new.conversation_id
    and cp.profile_id <> new.sender_id;
  return new;
end;
$$;
create trigger trg_notify_new_message after insert on public.messages
  for each row execute function public.notify_new_message();

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
