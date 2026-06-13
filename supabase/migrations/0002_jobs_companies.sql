-- 0002_jobs_companies.sql
-- Companies (+ gallery, people), job categories, jobs. This `jobs` table is the
-- source mirrored into Meilisearch (see 0007).

-- ---------------------------------------------------------------------------
-- companies
-- ---------------------------------------------------------------------------
create table public.companies (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  slug            text unique not null,
  logo_url        text,
  cover_url       text,
  about           text,
  industry        text,
  size            text,
  founded_year    int,
  website         text,
  headquarters    text,
  lat             double precision,
  lng             double precision,
  intro_video_url text,
  is_verified     boolean not null default false,
  owner_id        uuid references public.profiles(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index on public.companies (slug);
create trigger trg_companies_updated_at before update on public.companies
  for each row execute function public.set_updated_at();

alter table public.companies enable row level security;
create policy "companies readable by all" on public.companies for select using (true);
create policy "companies write owner"
  on public.companies for all to authenticated
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- Add the deferred soft-FK from experiences -> companies now that it exists.
alter table public.experiences
  add constraint experiences_company_id_fkey
  foreign key (company_id) references public.companies(id) on delete set null;

create table public.company_gallery (
  id         uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  media_url  text not null,
  media_type text not null default 'image' check (media_type in ('image','video')),
  caption    text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
create index on public.company_gallery (company_id, sort_order);

create table public.company_people (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies(id) on delete cascade,
  profile_id   uuid references public.profiles(id) on delete set null,
  name         text not null,
  title        text,
  avatar_url   text,
  is_recruiter boolean not null default false,
  created_at   timestamptz not null default now()
);
create index on public.company_people (company_id);

alter table public.company_gallery enable row level security;
alter table public.company_people  enable row level security;
create policy "company_gallery readable by all" on public.company_gallery for select using (true);
create policy "company_people readable by all"  on public.company_people  for select using (true);
create policy "company_gallery write owner" on public.company_gallery for all to authenticated
  using (exists (select 1 from public.companies c where c.id = company_id and c.owner_id = auth.uid()))
  with check (exists (select 1 from public.companies c where c.id = company_id and c.owner_id = auth.uid()));
create policy "company_people write owner" on public.company_people for all to authenticated
  using (exists (select 1 from public.companies c where c.id = company_id and c.owner_id = auth.uid()))
  with check (exists (select 1 from public.companies c where c.id = company_id and c.owner_id = auth.uid()));

-- ---------------------------------------------------------------------------
-- job categories
-- ---------------------------------------------------------------------------
create table public.job_categories (
  id   uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  icon text
);
alter table public.job_categories enable row level security;
create policy "job_categories readable by all" on public.job_categories for select using (true);

-- ---------------------------------------------------------------------------
-- jobs  (mirrored into Meilisearch)
-- ---------------------------------------------------------------------------
create table public.jobs (
  id               uuid primary key default gen_random_uuid(),
  company_id       uuid not null references public.companies(id) on delete cascade,
  posted_by        uuid references public.profiles(id) on delete set null,
  title            text not null,
  description      text,
  responsibilities text,
  requirements     text,
  benefits         text,
  category_id      uuid references public.job_categories(id) on delete set null,
  job_type         text check (job_type in ('full_time','part_time','contract','internship','temporary')),
  experience_level text check (experience_level in ('entry','mid','senior','lead')),
  working_model    text check (working_model in ('onsite','remote','hybrid')),
  location         text,
  country          text,
  city             text,
  lat              double precision,
  lng              double precision,
  salary_min       numeric,
  salary_max       numeric,
  currency         text default 'USD',
  salary_period    text default 'month' check (salary_period in ('hour','day','month','year')),
  skills_required  text[] not null default '{}',
  status           text not null default 'open' check (status in ('draft','open','closed')),
  applicants_count int not null default 0,
  views_count      int not null default 0,
  posted_at        timestamptz not null default now(),
  expires_at       timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index on public.jobs (company_id);
create index on public.jobs (status);
create index on public.jobs (category_id);
create index on public.jobs (posted_at desc);
create trigger trg_jobs_updated_at before update on public.jobs
  for each row execute function public.set_updated_at();

alter table public.jobs enable row level security;
create policy "jobs open readable by all"
  on public.jobs for select using (status = 'open');
create policy "jobs full access for poster"
  on public.jobs for all to authenticated
  using (auth.uid() = posted_by
         or exists (select 1 from public.companies c where c.id = company_id and c.owner_id = auth.uid()))
  with check (auth.uid() = posted_by
         or exists (select 1 from public.companies c where c.id = company_id and c.owner_id = auth.uid()));

-- normalized job <-> skill (optional; skills_required text[] kept for Meili)
create table public.job_skills (
  job_id   uuid not null references public.jobs(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  primary key (job_id, skill_id)
);

-- Read model: jobs joined with company display fields (cards / Meili source).
create or replace view public.job_feed
  with (security_invoker = true) as
  select
    j.*,
    c.name        as company_name,
    c.logo_url    as company_logo_url,
    c.is_verified as company_is_verified,
    cat.name      as category_name
  from public.jobs j
  join public.companies c on c.id = j.company_id
  left join public.job_categories cat on cat.id = j.category_id;
