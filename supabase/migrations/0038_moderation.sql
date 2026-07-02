-- 0038_moderation.sql
-- Platform moderation for the admin panel: block jobs/companies, suspend
-- profiles, hide reviews. Deliberately guarded COLUMNS (not new status enum
-- values) so owners can't revert an admin decision — same BEFORE-trigger +
-- txn-flag recipe as boosts (0011) and verification (0016), flag
-- `app.moderating`, with the is_admin() JWT escape hatch for parity with 0016.
-- Every RPC records itself in admin_audit_log (0037).

-- ---------------------------------------------------------------------------
-- Columns
-- ---------------------------------------------------------------------------
alter table public.jobs
  add column if not exists blocked_at     timestamptz,
  add column if not exists blocked_by     uuid references public.profiles(id) on delete set null,
  add column if not exists blocked_reason text;

alter table public.companies
  add column if not exists blocked_at     timestamptz,
  add column if not exists blocked_by     uuid references public.profiles(id) on delete set null,
  add column if not exists blocked_reason text;

alter table public.profiles
  add column if not exists suspended_at     timestamptz,
  add column if not exists suspended_by     uuid references public.profiles(id) on delete set null,
  add column if not exists suspended_reason text;

alter table public.company_reviews
  add column if not exists hidden_at     timestamptz,
  add column if not exists hidden_by     uuid references public.profiles(id) on delete set null,
  add column if not exists hidden_reason text;

alter table public.worker_reviews
  add column if not exists hidden_at     timestamptz,
  add column if not exists hidden_by     uuid references public.profiles(id) on delete set null,
  add column if not exists hidden_reason text;

-- ---------------------------------------------------------------------------
-- Guards: only admins (directly or via the flag-raising RPCs below) may write
-- moderation columns. Owners keep full row access otherwise, so without these
-- an employer could simply null out blocked_at on their own job.
-- ---------------------------------------------------------------------------
create or replace function public.guard_job_moderation()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.moderating', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.blocked_at := null;
    new.blocked_by := null;
    new.blocked_reason := null;
  else
    new.blocked_at := old.blocked_at;
    new.blocked_by := old.blocked_by;
    new.blocked_reason := old.blocked_reason;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_job_moderation on public.jobs;
create trigger trg_guard_job_moderation
  before insert or update on public.jobs
  for each row execute function public.guard_job_moderation();

create or replace function public.guard_company_moderation()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.moderating', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.blocked_at := null;
    new.blocked_by := null;
    new.blocked_reason := null;
  else
    new.blocked_at := old.blocked_at;
    new.blocked_by := old.blocked_by;
    new.blocked_reason := old.blocked_reason;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_company_moderation on public.companies;
create trigger trg_guard_company_moderation
  before insert or update on public.companies
  for each row execute function public.guard_company_moderation();

create or replace function public.guard_profile_moderation()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.moderating', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.suspended_at := null;
    new.suspended_by := null;
    new.suspended_reason := null;
  else
    new.suspended_at := old.suspended_at;
    new.suspended_by := old.suspended_by;
    new.suspended_reason := old.suspended_reason;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_profile_moderation on public.profiles;
create trigger trg_guard_profile_moderation
  before insert or update on public.profiles
  for each row execute function public.guard_profile_moderation();

create or replace function public.guard_company_review_moderation()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.moderating', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.hidden_at := null;
    new.hidden_by := null;
    new.hidden_reason := null;
  else
    new.hidden_at := old.hidden_at;
    new.hidden_by := old.hidden_by;
    new.hidden_reason := old.hidden_reason;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_company_review_moderation on public.company_reviews;
create trigger trg_guard_company_review_moderation
  before insert or update on public.company_reviews
  for each row execute function public.guard_company_review_moderation();

create or replace function public.guard_worker_review_moderation()
returns trigger language plpgsql as $$
begin
  if public.is_admin()
     or coalesce(current_setting('app.moderating', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.hidden_at := null;
    new.hidden_by := null;
    new.hidden_reason := null;
  else
    new.hidden_at := old.hidden_at;
    new.hidden_by := old.hidden_by;
    new.hidden_reason := old.hidden_reason;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_guard_worker_review_moderation on public.worker_reviews;
create trigger trg_guard_worker_review_moderation
  before insert or update on public.worker_reviews
  for each row execute function public.guard_worker_review_moderation();

-- ---------------------------------------------------------------------------
-- Hidden reviews disappear from readers (except the admin and the author).
-- The `for all` write-own policies still grant authors select of their own
-- rows, which is intended — they just can't unhide (guard above).
-- ---------------------------------------------------------------------------
drop policy if exists "company_reviews readable by all" on public.company_reviews;
create policy "company_reviews readable by all"
  on public.company_reviews for select
  using (hidden_at is null or public.is_admin() or auth.uid() = author_id);

drop policy if exists "worker_reviews readable by authenticated" on public.worker_reviews;
create policy "worker_reviews readable by authenticated"
  on public.worker_reviews for select to authenticated
  using (hidden_at is null or public.is_admin() or auth.uid() = author_id);

-- Aggregates must not count hidden reviews (same columns -> create or replace).
create or replace view public.company_rating_summary
  with (security_invoker = true) as
  select company_id,
         round(avg(rating)::numeric, 2) as avg_rating,
         count(*)                       as review_count
  from public.company_reviews
  where hidden_at is null
  group by company_id;

create or replace view public.worker_reliability_summary
  with (security_invoker = true) as
  select worker_id,
         round(avg(rating)::numeric, 2)      as avg_rating,
         round(avg(reliability)::numeric, 2) as avg_reliability,
         count(*)                            as review_count,
         round(
           (coalesce(avg(rating), 0) * 0.6
            + coalesce(avg(reliability), avg(rating), 0) * 0.4) * 20
         )::int                              as reliability_score
  from public.worker_reviews
  where hidden_at is null
  group by worker_id;

-- ---------------------------------------------------------------------------
-- Feed: blocked jobs and jobs of blocked companies vanish from every seeker
-- surface at once (both apps read job_feed). Employers still see their own
-- rows in the dashboard, which reads the jobs table directly. Drop + recreate
-- (not create-or-replace) to keep the j.* column order stable — the new jobs
-- moderation columns are appended before this runs, and blocked rows are
-- filtered out, so blocked_reason never surfaces to seekers.
-- ---------------------------------------------------------------------------
drop view if exists public.job_feed;
create view public.job_feed
  with (security_invoker = true) as
  select
    j.*,
    (j.boosted_until is not null and j.boosted_until > now()) as boost_active,
    c.name        as company_name,
    c.logo_url    as company_logo_url,
    c.is_verified as company_is_verified,
    cat.name      as category_name
  from public.jobs j
  join public.companies c on c.id = j.company_id
  left join public.job_categories cat on cat.id = j.category_id
  where (j.expires_at is null or j.expires_at > now())
    and j.blocked_at is null
    and c.blocked_at is null;

-- ---------------------------------------------------------------------------
-- Admin RPCs (pattern: 0016). Block/unblock notify the owner via the standard
-- notifications pipeline (type 'system' -> in-app + Telegram + push, 0026).
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_job_blocked(
  p_job uuid, p_blocked boolean, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_title text;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.moderating', '1', true);
  update public.jobs
     set blocked_at     = case when p_blocked then now() end,
         blocked_by     = case when p_blocked then auth.uid() end,
         blocked_reason = case when p_blocked then p_reason end
   where id = p_job;
  perform set_config('app.moderating', '0', true);

  select c.owner_id, j.title into v_owner, v_title
    from public.jobs j join public.companies c on c.id = j.company_id
   where j.id = p_job;
  if p_blocked and v_owner is not null then
    insert into public.notifications (recipient_id, type, title, body, data)
    values (v_owner, 'system', 'E''lon bloklandi',
            coalesce(v_title, '') || case when p_reason is not null
              then ' — ' || p_reason else '' end,
            jsonb_build_object('job_id', p_job));
  end if;

  perform public.admin_audit(
    case when p_blocked then 'job.block' else 'job.unblock' end,
    'jobs', p_job::text, jsonb_build_object('reason', p_reason));
end;
$$;
grant execute on function public.admin_set_job_blocked(uuid, boolean, text) to authenticated;

create or replace function public.admin_set_company_blocked(
  p_company uuid, p_blocked boolean, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_name text;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.moderating', '1', true);
  update public.companies
     set blocked_at     = case when p_blocked then now() end,
         blocked_by     = case when p_blocked then auth.uid() end,
         blocked_reason = case when p_blocked then p_reason end
   where id = p_company;
  perform set_config('app.moderating', '0', true);

  select owner_id, name into v_owner, v_name
    from public.companies where id = p_company;
  if p_blocked and v_owner is not null then
    insert into public.notifications (recipient_id, type, title, body, data)
    values (v_owner, 'system', 'Kompaniya bloklandi',
            coalesce(v_name, '') || case when p_reason is not null
              then ' — ' || p_reason else '' end,
            jsonb_build_object('company_id', p_company));
  end if;

  perform public.admin_audit(
    case when p_blocked then 'company.block' else 'company.unblock' end,
    'companies', p_company::text, jsonb_build_object('reason', p_reason));
end;
$$;
grant execute on function public.admin_set_company_blocked(uuid, boolean, text) to authenticated;

-- Marks the profile row; the panel's server action additionally bans the auth
-- user via the Admin API (service role) so a suspended account can't sign in.
create or replace function public.admin_set_profile_suspended(
  p_profile uuid, p_suspended boolean, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.moderating', '1', true);
  update public.profiles
     set suspended_at     = case when p_suspended then now() end,
         suspended_by     = case when p_suspended then auth.uid() end,
         suspended_reason = case when p_suspended then p_reason end
   where id = p_profile;
  perform set_config('app.moderating', '0', true);

  perform public.admin_audit(
    case when p_suspended then 'profile.suspend' else 'profile.unsuspend' end,
    'profiles', p_profile::text, jsonb_build_object('reason', p_reason));
end;
$$;
grant execute on function public.admin_set_profile_suspended(uuid, boolean, text) to authenticated;

create or replace function public.admin_set_company_review_hidden(
  p_review uuid, p_hidden boolean, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.moderating', '1', true);
  update public.company_reviews
     set hidden_at     = case when p_hidden then now() end,
         hidden_by     = case when p_hidden then auth.uid() end,
         hidden_reason = case when p_hidden then p_reason end
   where id = p_review;
  perform set_config('app.moderating', '0', true);

  perform public.admin_audit(
    case when p_hidden then 'company_review.hide' else 'company_review.show' end,
    'company_reviews', p_review::text, jsonb_build_object('reason', p_reason));
end;
$$;
grant execute on function public.admin_set_company_review_hidden(uuid, boolean, text) to authenticated;

create or replace function public.admin_set_worker_review_hidden(
  p_review uuid, p_hidden boolean, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  perform set_config('app.moderating', '1', true);
  update public.worker_reviews
     set hidden_at     = case when p_hidden then now() end,
         hidden_by     = case when p_hidden then auth.uid() end,
         hidden_reason = case when p_hidden then p_reason end
   where id = p_review;
  perform set_config('app.moderating', '0', true);

  perform public.admin_audit(
    case when p_hidden then 'worker_review.hide' else 'worker_review.show' end,
    'worker_reviews', p_review::text, jsonb_build_object('reason', p_reason));
end;
$$;
grant execute on function public.admin_set_worker_review_hidden(uuid, boolean, text) to authenticated;
