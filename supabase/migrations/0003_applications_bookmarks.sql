-- 0003_applications_bookmarks.sql
-- Job applications + status timeline + bookmarks.

create table public.applications (
  id             uuid primary key default gen_random_uuid(),
  job_id         uuid not null references public.jobs(id) on delete cascade,
  applicant_id   uuid not null references public.profiles(id) on delete cascade,
  resume_id      uuid references public.resumes(id) on delete set null,
  cover_letter   text,
  answers        jsonb not null default '{}',         -- screening answers from Apply screen
  current_status text not null default 'submitted'
                  check (current_status in ('submitted','viewed','shortlisted','interview','offer','rejected','hired')),
  applied_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (job_id, applicant_id)
);
create index on public.applications (applicant_id);
create index on public.applications (job_id);
create trigger trg_applications_updated_at before update on public.applications
  for each row execute function public.set_updated_at();

create table public.application_status_history (
  id             uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  status         text not null
                  check (status in ('submitted','viewed','shortlisted','interview','offer','rejected','hired')),
  note           text,
  changed_by     uuid references public.profiles(id) on delete set null,
  changed_at     timestamptz not null default now()
);
create index on public.application_status_history (application_id, changed_at);

create table public.bookmarks (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  job_id     uuid not null references public.jobs(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, job_id)
);
create index on public.bookmarks (profile_id);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.applications enable row level security;
alter table public.application_status_history enable row level security;
alter table public.bookmarks enable row level security;

-- Helper: does auth.uid() own the company that posted this job?
create or replace function public.is_job_owner(p_job_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.jobs j
    join public.companies c on c.id = j.company_id
    where j.id = p_job_id and (c.owner_id = auth.uid() or j.posted_by = auth.uid())
  );
$$;

create policy "applications visible to applicant or job owner"
  on public.applications for select to authenticated
  using (auth.uid() = applicant_id or public.is_job_owner(job_id));
create policy "applications insert by applicant"
  on public.applications for insert to authenticated
  with check (auth.uid() = applicant_id);
create policy "applications update by applicant or owner"
  on public.applications for update to authenticated
  using (auth.uid() = applicant_id or public.is_job_owner(job_id));

create policy "status history visible to applicant or owner"
  on public.application_status_history for select to authenticated
  using (exists (
    select 1 from public.applications a
    where a.id = application_id
      and (a.applicant_id = auth.uid() or public.is_job_owner(a.job_id))
  ));
create policy "status history insert by applicant or owner"
  on public.application_status_history for insert to authenticated
  with check (exists (
    select 1 from public.applications a
    where a.id = application_id
      and (a.applicant_id = auth.uid() or public.is_job_owner(a.job_id))
  ));

create policy "bookmarks own"
  on public.bookmarks for all to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- ---------------------------------------------------------------------------
-- Triggers: keep applicants_count + status in sync, seed initial history row
-- ---------------------------------------------------------------------------
create or replace function public.on_application_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.jobs set applicants_count = applicants_count + 1 where id = new.job_id;
  insert into public.application_status_history (application_id, status, changed_by)
  values (new.id, new.current_status, new.applicant_id);
  return new;
end;
$$;
create trigger trg_application_insert after insert on public.applications
  for each row execute function public.on_application_insert();

create or replace function public.on_application_delete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.jobs set applicants_count = greatest(applicants_count - 1, 0) where id = old.job_id;
  return old;
end;
$$;
create trigger trg_application_delete after delete on public.applications
  for each row execute function public.on_application_delete();

-- When a new history row is added, denormalize latest status onto the application.
create or replace function public.sync_application_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.applications
    set current_status = new.status, updated_at = now()
    where id = new.application_id;
  return new;
end;
$$;
create trigger trg_sync_application_status after insert on public.application_status_history
  for each row execute function public.sync_application_status();
