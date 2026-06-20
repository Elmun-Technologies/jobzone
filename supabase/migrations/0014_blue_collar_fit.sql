-- 0014_blue_collar_fit.sql
-- hh-style blue-collar posting depth: rotational (Вахта) work, schedule
-- patterns, hours/day, night shifts, and employment formalization.

-- Employment type: add rotational (Вахта) alongside the existing types.
alter table public.jobs drop constraint if exists jobs_job_type_check;
alter table public.jobs
  add constraint jobs_job_type_check
  check (
    job_type is null
    or job_type in (
      'full_time','part_time','contract','internship','temporary','rotational'
    )
  );

-- Work schedule pattern ("График работы"): days-on/days-off or custom.
alter table public.jobs
  add column if not exists schedule_pattern text
  check (
    schedule_pattern is null
    or schedule_pattern in ('6_1','5_2','4_4','2_2','custom')
  );

-- Hours per day and night-shift availability.
alter table public.jobs
  add column if not exists hours_per_day numeric
  check (hours_per_day is null or (hours_per_day > 0 and hours_per_day <= 24));
alter table public.jobs
  add column if not exists night_shift boolean not null default false;

-- Employment formalization ("Оформление сотрудника").
alter table public.jobs
  add column if not exists formalization text
  check (
    formalization is null
    or formalization in ('employment_contract','gph','self_employed','none')
  );
