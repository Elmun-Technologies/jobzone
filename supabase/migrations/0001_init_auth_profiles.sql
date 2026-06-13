-- 0001_init_auth_profiles.sql
-- Identity, profile and CV domain.
-- Tables: profiles + all CV sub-sections, contact info, lookups, preferences, settings.
-- RLS is enabled on every table. Convention: uuid PKs, created_at/updated_at, set_updated_at trigger.

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Lookups
-- ---------------------------------------------------------------------------
create table public.seeking_statuses (
  id   smallint primary key,
  code text unique not null         -- localized client-side by code
);
insert into public.seeking_statuses (id, code) values
  (1, 'actively_looking'),
  (2, 'open_to_offers'),
  (3, 'not_looking')
on conflict do nothing;

alter table public.seeking_statuses enable row level security;
create policy "seeking_statuses readable by all"
  on public.seeking_statuses for select using (true);

-- ---------------------------------------------------------------------------
-- profiles  (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  full_name           text,
  headline            text,
  bio                 text,
  avatar_url          text,
  cover_url           text,
  phone               text,
  email               text,
  country             text,
  city                text,
  lat                 double precision,
  lng                 double precision,
  intro_video_url     text,
  is_open_to_work     boolean  not null default true,
  seeking_status_id   smallint references public.seeking_statuses(id) default 1,
  preferred_locale    text     not null default 'en',
  onboarding_complete boolean  not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create trigger trg_profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
create policy "profiles selectable by authenticated"
  on public.profiles for select to authenticated using (true);
create policy "profiles insert own"
  on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles update own"
  on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Public-safe projection (recruiter browsing, chat participant display, etc.)
create or replace view public.profiles_public
  with (security_invoker = true) as
  select id, full_name, headline, avatar_url, cover_url, city, country, is_open_to_work
  from public.profiles;

-- ---------------------------------------------------------------------------
-- contact_info  (mirrors the Contact Info screen)
-- ---------------------------------------------------------------------------
create table public.contact_info (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  website    text,
  linkedin   text,
  github     text,
  telegram   text,
  address    text,
  updated_at timestamptz not null default now()
);
create trigger trg_contact_info_updated_at before update on public.contact_info
  for each row execute function public.set_updated_at();

alter table public.contact_info enable row level security;
create policy "contact_info selectable by authenticated"
  on public.contact_info for select to authenticated using (true);
create policy "contact_info write own"
  on public.contact_info for all to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- ---------------------------------------------------------------------------
-- preferences + notification settings
-- ---------------------------------------------------------------------------
create table public.user_preferences (
  profile_id          uuid primary key references public.profiles(id) on delete cascade,
  job_types           text[] not null default '{}',
  experience_levels   text[] not null default '{}',
  working_models      text[] not null default '{}',
  desired_titles      text[] not null default '{}',
  desired_locations   text[] not null default '{}',
  salary_expectation  numeric,
  currency            text default 'USD',
  updated_at          timestamptz not null default now()
);
create trigger trg_user_preferences_updated_at before update on public.user_preferences
  for each row execute function public.set_updated_at();

alter table public.user_preferences enable row level security;
create policy "user_preferences own"
  on public.user_preferences for all to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

create table public.notification_settings (
  profile_id        uuid primary key references public.profiles(id) on delete cascade,
  push_messages     boolean not null default true,
  push_application  boolean not null default true,
  push_job_match    boolean not null default true,
  push_reviews      boolean not null default true,
  email_messages    boolean not null default false,
  email_application boolean not null default true,
  email_job_match   boolean not null default false,
  updated_at        timestamptz not null default now()
);
create trigger trg_notification_settings_updated_at before update on public.notification_settings
  for each row execute function public.set_updated_at();

alter table public.notification_settings enable row level security;
create policy "notification_settings own"
  on public.notification_settings for all to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- ---------------------------------------------------------------------------
-- CV sub-sections (each owner-scoped; readable by authenticated for recruiter view)
-- ---------------------------------------------------------------------------
create table public.experiences (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.profiles(id) on delete cascade,
  title         text not null,
  company_name  text,
  company_id    uuid,                       -- soft link; FK added after companies exists
  employment_type text,
  location      text,
  working_model text,
  start_date    date,
  end_date      date,
  is_current    boolean not null default false,
  description   text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index on public.experiences (profile_id);
create trigger trg_experiences_updated_at before update on public.experiences
  for each row execute function public.set_updated_at();

create table public.educations (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  school      text not null,
  degree      text,
  field       text,
  start_date  date,
  end_date    date,
  grade       text,
  description text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index on public.educations (profile_id);
create trigger trg_educations_updated_at before update on public.educations
  for each row execute function public.set_updated_at();

create table public.projects (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  name        text not null,
  role        text,
  url         text,
  start_date  date,
  end_date    date,
  description text,
  media_urls  text[] not null default '{}',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index on public.projects (profile_id);
create trigger trg_projects_updated_at before update on public.projects
  for each row execute function public.set_updated_at();

create table public.certifications (
  id             uuid primary key default gen_random_uuid(),
  profile_id     uuid not null references public.profiles(id) on delete cascade,
  name           text not null,
  issuer         text,
  credential_id  text,
  credential_url text,
  issued_date    date,
  expiry_date    date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index on public.certifications (profile_id);
create trigger trg_certifications_updated_at before update on public.certifications
  for each row execute function public.set_updated_at();

create table public.volunteer_experiences (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  organization text not null,
  role         text,
  cause        text,
  start_date   date,
  end_date     date,
  description  text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index on public.volunteer_experiences (profile_id);
create trigger trg_volunteer_experiences_updated_at before update on public.volunteer_experiences
  for each row execute function public.set_updated_at();

create table public.awards (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  title       text not null,
  issuer      text,
  date        date,
  description text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index on public.awards (profile_id);
create trigger trg_awards_updated_at before update on public.awards
  for each row execute function public.set_updated_at();

-- Skills catalog (shared) + per-profile join
create table public.skills (
  id   uuid primary key default gen_random_uuid(),
  name text unique not null
);
alter table public.skills enable row level security;
create policy "skills readable by all" on public.skills for select using (true);
create policy "skills insert by authenticated" on public.skills
  for insert to authenticated with check (true);

create table public.profile_skills (
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  skill_id    uuid not null references public.skills(id) on delete cascade,
  proficiency text,
  years       numeric,
  primary key (profile_id, skill_id)
);
create index on public.profile_skills (skill_id);

create table public.resumes (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  title       text not null,
  file_path   text not null,               -- storage key in `resumes` bucket
  file_size   bigint,
  mime_type   text,
  is_default  boolean not null default false,
  uploaded_at timestamptz not null default now()
);
create index on public.resumes (profile_id);

-- RLS for CV tables: readable by authenticated, writable by owner only
do $$
declare t text;
begin
  foreach t in array array[
    'experiences','educations','projects','certifications',
    'volunteer_experiences','awards','profile_skills'
  ] loop
    execute format('alter table public.%I enable row level security;', t);
    execute format($f$create policy "%1$s selectable by authenticated" on public.%1$I
                       for select to authenticated using (true);$f$, t);
    execute format($f$create policy "%1$s write own" on public.%1$I
                       for all to authenticated
                       using (auth.uid() = profile_id) with check (auth.uid() = profile_id);$f$, t);
  end loop;
end $$;

-- Resumes are sensitive: owner-only (recruiters gain access via application context later)
alter table public.resumes enable row level security;
create policy "resumes own"
  on public.resumes for all to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- ---------------------------------------------------------------------------
-- Auto-provision profile + defaults on signup
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  insert into public.user_preferences (profile_id) values (new.id) on conflict do nothing;
  insert into public.notification_settings (profile_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
