-- 0079_invite_payload_parts.sql
-- Carry the company and the role in the invitation's payload, so the clients
-- can say it in the reader's language.
--
-- invite_candidate() (0050) writes the whole sentence in Uzbek:
--
--   'Ish taklifi',
--   v_company || ' sizni "' || v_title || '" lavozimiga taklif qilmoqda.',
--   jsonb_build_object('job_id', p_job_id, 'invited', true)
--
-- Being invited by name is the most flattering thing that happens to a seeker
-- on this platform, and a Russian- or English-reading one cannot read it. The
-- payload marks the row (`invited`) but carries neither of the two words the
-- sentence is built from, so no client can rebuild it — 0078 hit exactly this
-- and solved it the same way, by putting the parts in `data`.
--
-- notify-dispatch already works around this for Telegram/push by looking the
-- job up itself. That lookup stays as the fallback for rows written before
-- this migration; new rows no longer need it.
--
-- The stored title/body stay as they are. They remain the fallback for any
-- client that predates this, and for the same reason the sentence is still
-- worth writing: an old row is no worse off than it is today.

create or replace function public.invite_candidate(p_job_id uuid, p_candidate uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_title text;
  v_company text;
begin
  if not public.is_job_owner(p_job_id) then
    raise exception 'not authorized';
  end if;

  select j.title, c.name into v_title, v_company
  from public.jobs j
  join public.companies c on c.id = j.company_id
  where j.id = p_job_id;
  if v_title is null then
    raise exception 'job not found';
  end if;

  -- Don't re-notify: one invitation per (job, candidate).
  if exists (
    select 1 from public.notifications n
    where n.recipient_id = p_candidate
      and n.type = 'job_match'
      and n.data->>'job_id' = p_job_id::text
      and n.data->>'invited' = 'true'
  ) then
    return;
  end if;

  insert into public.notifications (recipient_id, type, title, body, data)
  values (
    p_candidate, 'job_match',
    'Ish taklifi',
    v_company || ' sizni "' || v_title || '" lavozimiga taklif qilmoqda.',
    -- `company` and `title` are the two words the sentence is made of; with
    -- them in the payload every client writes it in its own language.
    jsonb_build_object(
      'job_id', p_job_id,
      'invited', true,
      'company', v_company,
      'title', v_title
    )
  );
end;
$$;
