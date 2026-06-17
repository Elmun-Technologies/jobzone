-- ---------------------------------------------------------------------------
-- Account role: job seeker vs employer (HR)
-- ---------------------------------------------------------------------------
-- Adds a role to every profile so the app can branch between the job-seeker
-- experience and the employer ("Jobzone Business") experience. Defaults to
-- 'job_seeker' so existing rows backfill automatically and the seeker side is
-- unaffected. Employers link to a company via the existing companies.owner_id.

alter table public.profiles
  add column if not exists role text not null default 'job_seeker'
  check (role in ('job_seeker', 'employer'));

-- Persist a role chosen at signup (passed in auth metadata) atomically with
-- profile provisioning. Falls back to 'job_seeker' when unset. This replaces
-- the function body from 0001; the on_auth_user_created trigger still points
-- at it by name, so no trigger change is needed.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'role', 'job_seeker')
  )
  on conflict (id) do nothing;
  insert into public.user_preferences (profile_id) values (new.id) on conflict do nothing;
  insert into public.notification_settings (profile_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;
