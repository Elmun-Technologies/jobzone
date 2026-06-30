-- Resume builder: extra self-described profile fields collected by the
-- /resumes/new wizard. Additive and idempotent. Expected pay reuses the
-- desired_pay_* columns from 0017; work history / education use the existing
-- experiences / educations tables.
alter table public.profiles
  add column if not exists gender text
    check (gender is null or gender in ('male', 'female')),
  add column if not exists birth_date date,
  add column if not exists marital_status text
    check (marital_status is null
           or marital_status in ('single', 'married', 'divorced')),
  add column if not exists experience_level text
    check (experience_level is null
           or experience_level in ('none', 'under_1', '1_3', '3_5', '5_plus'));
