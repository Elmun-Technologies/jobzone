-- 0037_admin_foundation.sql
-- Platform admin panel foundation: an audit trail for every admin action and
-- one aggregate RPC that powers the /admin analytics dashboard. Builds on the
-- existing admin gate `is_admin()` (0016_verification.sql — JWT
-- app_metadata.role = 'admin'); this is its first client-facing consumer.

-- ---------------------------------------------------------------------------
-- Audit log. Rows are written only from inside admin security-definer RPCs
-- (via admin_audit() below) — clients get no insert policy, and only admins
-- may read it.
-- ---------------------------------------------------------------------------
create table if not exists public.admin_audit_log (
  id          bigint generated always as identity primary key,
  actor_id    uuid references public.profiles(id) on delete set null,
  action      text not null,             -- 'job.block', 'wallet.complete_topup', …
  target_type text,
  target_id   text,
  meta        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);
create index if not exists admin_audit_log_created_idx
  on public.admin_audit_log (created_at desc);

alter table public.admin_audit_log enable row level security;

drop policy if exists "audit readable by admins" on public.admin_audit_log;
create policy "audit readable by admins"
  on public.admin_audit_log for select to authenticated
  using (public.is_admin());
-- No insert/update/delete policies: writes happen only inside definer RPCs.

-- Helper every admin RPC calls after its write. Definer-to-definer calls run
-- as the function owner, so revoking client execute below does not block them.
create or replace function public.admin_audit(
  p_action text, p_target_type text, p_target_id text,
  p_meta jsonb default '{}'::jsonb
) returns void language sql security definer set search_path = public as $$
  insert into public.admin_audit_log (actor_id, action, target_type, target_id, meta)
  values (auth.uid(), p_action, p_target_type, p_target_id, coalesce(p_meta, '{}'::jsonb));
$$;
revoke all on function public.admin_audit(text, text, text, jsonb) from public;

-- ---------------------------------------------------------------------------
-- Dashboard aggregates. One admin-gated round-trip returning everything the
-- panel's overview needs; RLS-exempt via security definer so it can count
-- across all owners (profiles/wallets are owner-scoped for normal clients).
-- Series buckets are creation-based daily counts (there is no event log yet).
-- ---------------------------------------------------------------------------
create or replace function public.admin_dashboard_stats(p_days int default 30)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_from timestamptz := now() - make_interval(days => greatest(coalesce(p_days, 30), 1));
  v jsonb;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;

  select jsonb_build_object(
    'totals', jsonb_build_object(
      'seekers',            (select count(*) from profiles where role = 'job_seeker'),
      'employers',          (select count(*) from profiles where role = 'employer'),
      'companies',          (select count(*) from companies),
      'companies_verified', (select count(*) from companies where is_verified),
      'workers_verified',   (select count(*) from profiles where worker_verified_at is not null),
      'jobs_open',          (select count(*) from jobs where status = 'open'),
      'jobs_total',         (select count(*) from jobs),
      'applications',       (select count(*) from applications),
      'devices',            (select count(*) from devices),
      'telegram_linked',    (select count(*) from telegram_links)),
    'series', jsonb_build_object(
      'signups', (select coalesce(jsonb_agg(jsonb_build_object('d', d, 'n', n) order by d), '[]'::jsonb)
        from (select date_trunc('day', created_at)::date d, count(*) n
              from profiles where created_at >= v_from group by 1) t),
      'jobs', (select coalesce(jsonb_agg(jsonb_build_object('d', d, 'n', n) order by d), '[]'::jsonb)
        from (select date_trunc('day', created_at)::date d, count(*) n
              from jobs where created_at >= v_from group by 1) t),
      'applications', (select coalesce(jsonb_agg(jsonb_build_object('d', d, 'n', n) order by d), '[]'::jsonb)
        from (select date_trunc('day', applied_at)::date d, count(*) n
              from applications where applied_at >= v_from group by 1) t),
      'revenue', (select coalesce(jsonb_agg(jsonb_build_object('d', d, 'n', n) order by d), '[]'::jsonb)
        from (select date_trunc('day', paid_at)::date d, sum(amount_uzs) n
              from promotion_orders where status = 'paid' and paid_at >= v_from group by 1) t),
      'topups', (select coalesce(jsonb_agg(jsonb_build_object('d', d, 'n', n) order by d), '[]'::jsonb)
        from (select date_trunc('day', completed_at)::date d, sum(amount_uzs) n
              from wallet_transactions
              where kind = 'topup' and status = 'completed' and completed_at >= v_from group by 1) t)),
    'funnel', (select coalesce(jsonb_object_agg(status, n), '{}'::jsonb)
      from (select status, count(distinct application_id) n
            from application_status_history group by status) f),
    'top_categories', (select coalesce(jsonb_agg(jsonb_build_object('name', name, 'n', n) order by n desc), '[]'::jsonb)
      from (select cat.name, count(*) n
            from jobs j join job_categories cat on cat.id = j.category_id
            where j.status = 'open' group by cat.name order by n desc limit 10) t),
    'top_cities', (select coalesce(jsonb_agg(jsonb_build_object('city', city, 'n', n) order by n desc), '[]'::jsonb)
      from (select j.city, count(*) n
            from jobs j
            where j.status = 'open' and coalesce(j.city, '') <> '' group by j.city
            order by n desc limit 10) t),
    'finance', jsonb_build_object(
      'revenue_total',     (select coalesce(sum(amount_uzs), 0) from promotion_orders where status = 'paid'),
      'wallet_liability',  (select coalesce(sum(amount_uzs), 0) from wallet_transactions where status = 'completed'),
      'pending_topups',    (select count(*) from wallet_transactions where status = 'pending' and kind = 'topup'),
      'pending_topup_sum', (select coalesce(sum(amount_uzs), 0) from wallet_transactions where status = 'pending' and kind = 'topup'))
  ) into v;

  return v;
end;
$$;
grant execute on function public.admin_dashboard_stats(int) to authenticated;
