-- 0025_scheduled_publish.sql
-- Scheduled publishing: an employer can set a future `publish_at`; the job is
-- saved as a draft until then. `publish_due_jobs()` flips due drafts to open —
-- call it on a schedule (pg_cron / an edge cron) to activate them live.

alter table public.jobs
  add column if not exists publish_at timestamptz;

-- Flips scheduled drafts whose time has arrived to `open`. Security-definer so a
-- scheduler can run it; only touches rows that opted in via publish_at.
create or replace function public.publish_due_jobs()
  returns integer
  language sql
  security definer
  set search_path = public
as $$
  with flipped as (
    update public.jobs
       set status = 'open', publish_at = null
     where status = 'draft'
       and publish_at is not null
       and publish_at <= now()
    returning 1
  )
  select count(*)::int from flipped;
$$;

-- Recreate the seeker feed so `j.*` re-exposes `publish_at`. Drop first —
-- `create or replace view` rejects the column-order shift (42P16).
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
  left join public.job_categories cat on cat.id = j.category_id;
