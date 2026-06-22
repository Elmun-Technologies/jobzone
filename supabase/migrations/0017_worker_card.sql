-- 0017_worker_card.sql
-- CV-less worker card fields: desired pay + availability. Skills (profile_skills),
-- photo, phone, location and is_open_to_work already live on profiles.
alter table public.profiles
  add column if not exists desired_pay_min      numeric,
  add column if not exists desired_pay_max      numeric,
  add column if not exists desired_pay_currency text not null default 'UZS'
    check (desired_pay_currency in ('UZS','USD')),
  add column if not exists availability text
    check (availability is null
           or availability in ('immediate','two_weeks','flexible'));

-- Re-project the public view with the worker-card fields (verification booleans
-- were added in 0016).
create or replace view public.profiles_public
  with (security_invoker = true) as
  select id, full_name, headline, avatar_url, cover_url, city, country,
         is_open_to_work,
         (phone_verified_at is not null)  as phone_verified,
         (worker_verified_at is not null) as worker_verified,
         desired_pay_min, desired_pay_max, desired_pay_currency, availability
  from public.profiles;
