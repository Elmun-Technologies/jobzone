-- 0056_admin_broadcast.sql
-- Broadcast: lets the technical team send one in-app notification to a whole
-- audience (all users, seekers only, or employers only, optionally scoped to a
-- city). Reuses the entire existing notification pipeline — each inserted
-- `notifications` row (type='system') fires the 0026 AFTER-INSERT trigger,
-- which fans out to the recipient's Telegram/push honoring their
-- notification_settings. No new delivery code.
--
-- Safety: notifications has no client INSERT policy (definer-only), so this
-- SECURITY DEFINER RPC is the only path. A hard audience cap rejects an
-- oversized send so a fat-fingered "all" can't mass-spam — the admin narrows
-- by city (or splits the send) instead.

create or replace function public.admin_broadcast(
  p_title text,
  p_body text,
  p_audience text default 'all',
  p_city text default null
) returns int language plpgsql security definer set search_path = public as $$
declare
  v_cap   int := 5000;   -- max recipients per single broadcast
  v_count int;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_audience not in ('all', 'seekers', 'employers') then
    raise exception 'invalid audience';
  end if;
  if coalesce(trim(p_title), '') = '' then
    raise exception 'title is required';
  end if;

  -- Resolve the audience once so the count and the insert can't diverge.
  create temporary table _broadcast_targets on commit drop as
    select p.id
    from public.profiles p
    where p.suspended_at is null
      and (
        p_audience = 'all'
        or (p_audience = 'seekers' and p.role = 'job_seeker')
        or (p_audience = 'employers' and p.role = 'employer')
      )
      and (p_city is null or p_city = '' or p.city = p_city);

  select count(*) into v_count from _broadcast_targets;
  if v_count = 0 then
    raise exception 'no recipients match this audience';
  end if;
  if v_count > v_cap then
    raise exception
      'audience too large (% recipients, max %) — narrow by city or split the send',
      v_count, v_cap;
  end if;

  insert into public.notifications (recipient_id, type, title, body, data)
    select t.id, 'system', trim(p_title), nullif(trim(coalesce(p_body, '')), ''),
           jsonb_build_object('broadcast', true, 'audience', p_audience)
    from _broadcast_targets t;

  perform public.admin_audit(
    'broadcast.send', 'notifications', null,
    jsonb_build_object('audience', p_audience, 'city', p_city, 'count', v_count)
  );

  return v_count;
end;
$$;
grant execute on function public.admin_broadcast(text, text, text, text) to authenticated;
