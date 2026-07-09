-- 0052_dismissed_jobs.sql
-- "Archive" / "not interested" — a seeker can dismiss a job from their main
-- feed, giving them partial control over what keeps surfacing there. Mirrors
-- `bookmarks` exactly (same shape, same RLS pattern) so both clients can reuse
-- the identical read/write pattern they already use for bookmarks.

create table public.dismissed_jobs (
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  job_id       uuid not null references public.jobs(id) on delete cascade,
  dismissed_at timestamptz not null default now(),
  primary key (profile_id, job_id)
);
create index on public.dismissed_jobs (profile_id);

alter table public.dismissed_jobs enable row level security;
create policy "dismissed_jobs own"
  on public.dismissed_jobs for all to authenticated
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- A dismissed job shouldn't come back as a recommendation either.
create or replace function public.recommended_jobs()
returns setof public.job_feed
language sql stable
set search_path = public as $$
  with me as (
    select p.id as uid, p.city, p.headline
    from public.profiles p
    where p.id = auth.uid()
  )
  select jf.*
  from public.job_feed jf
  cross join me
  cross join lateral (
    select (
        (case when (jf.city is not null and me.city is not null
                    and lower(trim(jf.city)) = lower(trim(me.city)))
              then 3 else 0 end)
      + (case when (length(coalesce(trim(me.headline), '')) >= 3
                    and jf.title ilike '%' || trim(me.headline) || '%')
              then 3 else 0 end)
      + (case when exists (
            select 1 from public.experiences e
            where e.profile_id = me.uid
              and length(coalesce(trim(e.title), '')) >= 3
              and jf.title ilike '%' || trim(e.title) || '%'
          ) then 2 else 0 end)
      + least((
            select count(*) from public.profile_skills ps
            join public.skills s on s.id = ps.skill_id
            where ps.profile_id = me.uid
              and exists (
                select 1 from unnest(jf.skills_required) req
                where lower(trim(req)) = lower(trim(s.name))
              )
          )::int, 3)
    ) as score
  ) sc
  where jf.status = 'open'
    and sc.score > 0
    and not exists (
      select 1 from public.applications a
      where a.job_id = jf.id and a.applicant_id = me.uid
    )
    and not exists (
      select 1 from public.dismissed_jobs d
      where d.job_id = jf.id and d.profile_id = me.uid
    )
  order by sc.score desc, jf.boost_active desc, jf.posted_at desc nulls last
  limit 30;
$$;
