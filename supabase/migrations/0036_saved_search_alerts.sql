-- 0036_saved_search_alerts.sql
-- Turn saved searches into alerts: notify a seeker when a newly-posted open job
-- matches one of their saved searches. Delivery is free — the matcher just
-- INSERTs a `job_match` notification per match, and the existing notifications
-- AFTER-INSERT trigger (0026) fans each one out to in-app + Telegram + push,
-- already respecting the recipient's `push_job_match` setting.
--
-- A per-search watermark (`last_alerted_at`) makes each job alert at most once:
-- a run only considers jobs posted in (last_alerted_at, now], then advances the
-- watermark to now. New searches default the watermark to now(), so saving a
-- search never back-fills a flood of existing postings.
--
-- run_saved_search_alerts() does the matching; call it on a schedule (the
-- `saved-search-alerts` edge function, or pg_cron directly). See the go-live
-- checklist.

alter table public.saved_searches
  add column if not exists last_alerted_at timestamptz not null default now();

-- Scheduled publishing (0025) flips a due draft to open but left posted_at at
-- draft-creation time. Stamp posted_at at go-live instead, so a scheduled job
-- (a) sorts as freshly-posted in the feed and (b) falls inside the alert
-- matcher's (last_alerted_at, now] window when it becomes visible.
create or replace function public.publish_due_jobs()
  returns integer
  language sql
  security definer
  set search_path = public
as $$
  with flipped as (
    update public.jobs
       set status = 'open', publish_at = null, posted_at = now()
     where status = 'draft'
       and publish_at is not null
       and publish_at <= now()
    returning 1
  )
  select count(*)::int from flipped;
$$;

-- Matches newly-opened jobs against every saved search and inserts a job_match
-- notification per match, then advances each search's watermark. SECURITY
-- DEFINER so a scheduler (service role) can run it and so it can read all open
-- jobs + insert notifications (which RLS otherwise reserves for definers).
create or replace function public.run_saved_search_alerts()
  returns integer
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_now   timestamptz := now();
  v_count integer;
begin
  -- Serialize overlapping runs (manual trigger racing the cron) so a job can't
  -- be matched twice before the watermark advances. Released at txn end.
  perform pg_advisory_xact_lock(hashtext('run_saved_search_alerts'));

  with matches as (
    select
      ss.id         as ss_id,
      ss.profile_id as profile_id,
      j.id          as job_id,
      j.title       as job_title,
      c.name        as company_name,
      j.city        as city
    from public.saved_searches ss
    join public.jobs j
      on j.status = 'open'
     and (j.expires_at is null or j.expires_at > v_now)
     and j.posted_at > ss.last_alerted_at
     and j.posted_at <= v_now
    join public.companies c on c.id = j.company_id
    left join public.job_categories cat on cat.id = j.category_id
    where (ss.city is null or ss.city = '' or j.city = ss.city)
      and (
        ss.keywords is null or ss.keywords = ''
        or j.title  ilike '%' || ss.keywords || '%'
        or c.name   ilike '%' || ss.keywords || '%'
        or cat.name ilike '%' || ss.keywords || '%'
      )
  ),
  inserted as (
    insert into public.notifications (recipient_id, type, title, body, data)
    select
      m.profile_id,
      'job_match',
      m.job_title,
      concat_ws(' · ', m.company_name, nullif(m.city, '')),
      jsonb_build_object('job_id', m.job_id, 'saved_search_id', m.ss_id)
    from matches m
    returning 1
  )
  select count(*) into v_count from inserted;

  update public.saved_searches
     set last_alerted_at = v_now
   where last_alerted_at < v_now;

  return v_count;
end;
$$;

-- Only the service role (the edge function / scheduler) may run the matcher.
revoke all on function public.run_saved_search_alerts() from public;
grant execute on function public.run_saved_search_alerts() to service_role;
