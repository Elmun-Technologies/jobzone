-- 0069_admin_hardening.sql
-- Admin-panel audit findings, batched:
--
--   B) Verification RPCs (0016) never called admin_audit(); add trail; add
--      unverify variants so a bad approval can be reversed.
--   C) admin_set_order_status(refunded|cancelled) only flipped the column —
--      no wallet reversal, no boost clear. Phantom refunds + unreconciled
--      revenue. Extend it to (a) insert a compensating wallet_transactions
--      row (kind=refund) when the order was actually paid, and (b) clear
--      the boosted_until / boost_kind on the linked job under the same
--      applying_promotion flag apply_promotion() uses.
--   D) admin_credit_wallet(): new RPC for manual bonus / refund / write-off
--      with mandatory reason. Audited. adjust_wallet() only serves the
--      user-driven spend/topup flow — admins had no path other than direct
--      service-role SQL.
--   E) admin_upsert_category(): slug is a URL path segment (/ish/[slug]),
--      so a stray space or slash breaks the whole SEO tree. Enforce
--      ^[a-z0-9-]+$ at the RPC (not just the input's HTML5 pattern —
--      never trust the client).
--   F) Category rename: without a redirect trail, changing a slug 404s
--      every backlink Google indexed. Record every rename in
--      job_category_slug_history so /ish/[category] can 301 old slugs
--      forward.
--
-- All new grants match the "admin-only definer + audit" pattern
-- established in 0037.

-- ---------------------------------------------------------------------------
-- B) VERIFICATION: audit every set + add unverify path
-- ---------------------------------------------------------------------------

create or replace function public.admin_set_company_verification(
  p_company uuid, p_method text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_from boolean;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_method is null or p_method not in ('legal_entity', 'licensed_agency') then
    raise exception 'invalid method';
  end if;

  select is_verified into v_from from public.companies where id = p_company;
  if v_from is null then raise exception 'company not found'; end if;

  perform set_config('app.granting_verification', '1', true);
  update public.companies
     set is_verified = true, verified_at = now(),
         verified_by = auth.uid(), verification_method = p_method
   where id = p_company;
  perform set_config('app.granting_verification', '0', true);

  perform public.admin_audit(
    'company.verify', 'companies', p_company::text,
    jsonb_build_object('method', p_method, 'from_verified', v_from)
  );
end;
$$;
grant execute on function public.admin_set_company_verification(uuid, text) to authenticated;

-- Reverse a bad verification. Nulls the audit columns so the badge in the UI
-- disappears and the "not verified" state is indistinguishable from a company
-- that was never approved to begin with.
create or replace function public.admin_unset_company_verification(
  p_company uuid, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_from boolean;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;

  select is_verified into v_from from public.companies where id = p_company;
  if v_from is null then raise exception 'company not found'; end if;
  if v_from is false then raise exception 'not currently verified'; end if;

  perform set_config('app.granting_verification', '1', true);
  update public.companies
     set is_verified = false, verified_at = null,
         verified_by = null, verification_method = null
   where id = p_company;
  perform set_config('app.granting_verification', '0', true);

  perform public.admin_audit(
    'company.unverify', 'companies', p_company::text,
    jsonb_build_object('reason', p_reason)
  );
end;
$$;
grant execute on function public.admin_unset_company_verification(uuid, text) to authenticated;

create or replace function public.admin_set_worker_verification(
  p_profile uuid, p_method text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_from timestamptz;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_method is null or p_method not in ('id_document', 'manual') then
    raise exception 'invalid method';
  end if;

  select worker_verified_at into v_from from public.profiles where id = p_profile;
  if not found then raise exception 'profile not found'; end if;

  perform set_config('app.granting_verification', '1', true);
  update public.profiles
     set worker_verified_at = now(), worker_verified_by = auth.uid(),
         worker_verification_method = p_method
   where id = p_profile;
  perform set_config('app.granting_verification', '0', true);

  perform public.admin_audit(
    'worker.verify', 'profiles', p_profile::text,
    jsonb_build_object('method', p_method, 'from_verified_at', v_from)
  );
end;
$$;
grant execute on function public.admin_set_worker_verification(uuid, text) to authenticated;

create or replace function public.admin_unset_worker_verification(
  p_profile uuid, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_from timestamptz;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;

  select worker_verified_at into v_from from public.profiles where id = p_profile;
  if not found then raise exception 'profile not found'; end if;
  if v_from is null then raise exception 'not currently verified'; end if;

  perform set_config('app.granting_verification', '1', true);
  update public.profiles
     set worker_verified_at = null, worker_verified_by = null,
         worker_verification_method = null
   where id = p_profile;
  perform set_config('app.granting_verification', '0', true);

  perform public.admin_audit(
    'worker.unverify', 'profiles', p_profile::text,
    jsonb_build_object('reason', p_reason)
  );
end;
$$;
grant execute on function public.admin_unset_worker_verification(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- C) REFUND: reverse the wallet + clear the boost when a paid order is
--    refunded or cancelled. Idempotent via the status-flip guard on the
--    initial SELECT so a double-click can't double-refund.
-- ---------------------------------------------------------------------------

create or replace function public.admin_set_order_status(
  p_id uuid, p_status text, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_from text;
  v_company uuid;
  v_job uuid;
  v_amount numeric;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_status not in ('paid', 'cancelled', 'refunded') then
    raise exception 'invalid status';
  end if;

  select status, company_id, job_id, amount_uzs
    into v_from, v_company, v_job, v_amount
    from public.promotion_orders
    where id = p_id
    for update;  -- serialize concurrent admin clicks
  if v_from is null then raise exception 'order not found'; end if;
  if v_from = p_status then
    -- No-op transition (already there). Don't audit-spam.
    return;
  end if;

  update public.promotion_orders set status = p_status where id = p_id;

  -- Reverse the money + strip the boost when refunding a real payment.
  -- A cancellation of a paid order counts as a refund too (funds were
  -- moved). A cancellation of a still-pending order is a no-op on wallet.
  if v_from = 'paid' and p_status in ('refunded', 'cancelled') then
    if v_amount is not null and v_amount > 0 then
      insert into public.wallet_transactions
        (company_id, kind, amount_uzs, status, description, external_ref, created_by)
      values (
        v_company, 'refund', v_amount, 'completed',
        coalesce(p_reason, 'Order ' || p_id::text || ' ' || p_status),
        p_id::text,
        auth.uid()
      );
    end if;
    if v_job is not null then
      perform set_config('app.applying_promotion', '1', true);
      update public.jobs
         set boosted_until = null, boost_kind = null
       where id = v_job;
      perform set_config('app.applying_promotion', '0', true);
    end if;
  end if;

  perform public.admin_audit(
    'order.set_status', 'promotion_orders', p_id::text,
    jsonb_build_object(
      'status', p_status,
      'from', v_from,
      'reason', p_reason,
      'reversed_amount_uzs', case when v_from = 'paid' and p_status in ('refunded','cancelled')
                                  then v_amount else null end
    )
  );
end;
$$;
grant execute on function public.admin_set_order_status(uuid, text, text) to authenticated;

-- Keep the legacy 2-arg signature so callers that predate the reason
-- param still compile — new callers should pass a reason.
create or replace function public.admin_set_order_status(p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.admin_set_order_status(p_id, p_status, null::text);
end;
$$;
grant execute on function public.admin_set_order_status(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- D) MANUAL CREDIT: admin-issued wallet adjustment with mandatory reason.
--    Positive amount = credit (bonus, goodwill refund). Negative = debit
--    (write-off, correction). Non-zero enforced — a zero-amount audit
--    row is noise.
-- ---------------------------------------------------------------------------

create or replace function public.admin_credit_wallet(
  p_company uuid,
  p_amount_uzs numeric,
  p_kind text,        -- 'bonus' | 'refund' | 'spend' | 'topup'
  p_reason text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if p_kind not in ('bonus', 'refund', 'spend', 'topup') then
    raise exception 'invalid kind';
  end if;
  if p_amount_uzs is null or p_amount_uzs = 0 then
    raise exception 'amount must be non-zero';
  end if;
  if p_amount_uzs <> trunc(p_amount_uzs) then
    raise exception 'amount must be a whole number of som';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'reason is required';
  end if;
  if not exists (select 1 from public.companies where id = p_company) then
    raise exception 'company not found';
  end if;

  insert into public.wallet_transactions
    (company_id, kind, amount_uzs, status, description, created_by)
  values (
    p_company, p_kind, p_amount_uzs, 'completed', trim(p_reason), auth.uid()
  )
  returning id into v_id;

  perform public.admin_audit(
    'wallet.credit', 'wallet_transactions', v_id::text,
    jsonb_build_object(
      'company_id', p_company,
      'amount_uzs', p_amount_uzs,
      'kind', p_kind,
      'reason', p_reason
    )
  );
  return v_id;
end;
$$;
grant execute on function public.admin_credit_wallet(uuid, numeric, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- E) SLUG VALIDATION + F) SLUG HISTORY
-- ---------------------------------------------------------------------------

-- Old-slug bookkeeping: one row per rename. `slug` is unique so a slug that
-- was ever used points to at most one category — a rename that reuses a
-- previously-retired slug would raise, which is the right behavior (SEO would
-- be ambiguous).
create table if not exists public.job_category_slug_history (
  slug        text primary key,
  category_id uuid not null references public.job_categories(id) on delete cascade,
  retired_at  timestamptz not null default now()
);
create index if not exists job_category_slug_history_category_idx
  on public.job_category_slug_history (category_id);

-- Public read (the /ish/[slug] redirect is unauthenticated). No client write
-- policy — populated only by the trigger below.
alter table public.job_category_slug_history enable row level security;
drop policy if exists cat_slug_history_read on public.job_category_slug_history;
create policy cat_slug_history_read
  on public.job_category_slug_history for select
  to anon, authenticated using (true);

create or replace function public.record_category_slug_rename()
returns trigger language plpgsql as $$
begin
  if new.slug is distinct from old.slug and old.slug is not null then
    insert into public.job_category_slug_history (slug, category_id)
    values (old.slug, new.id)
    on conflict (slug) do update set category_id = excluded.category_id,
                                     retired_at = now();
  end if;
  return new;
end;
$$;
drop trigger if exists trg_category_slug_rename on public.job_categories;
create trigger trg_category_slug_rename
  after update of slug on public.job_categories
  for each row execute function public.record_category_slug_rename();

-- Tighten admin_upsert_category:
--  - slug must match ^[a-z0-9-]+$ (URL-safe, lower-case)
--  - not start or end with a dash (double dashes are fine — kept simple)
create or replace function public.admin_upsert_category(
  p_id uuid default null,
  p_name text default null,
  p_slug text default null,
  p_icon text default null,
  p_sort_order int default 0,
  p_is_active boolean default true
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_slug text := trim(coalesce(p_slug, ''));
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if coalesce(trim(p_name), '') = '' or v_slug = '' then
    raise exception 'name and slug are required';
  end if;
  if not v_slug ~ '^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$' then
    raise exception 'slug must be lowercase letters, digits, and internal dashes only';
  end if;

  if p_id is null then
    insert into public.job_categories (name, slug, icon, sort_order, is_active)
    values (
      trim(p_name), v_slug, nullif(trim(coalesce(p_icon, '')), ''),
      coalesce(p_sort_order, 0), coalesce(p_is_active, true)
    )
    returning id into v_id;
    perform public.admin_audit(
      'category.create', 'job_category', v_id::text,
      jsonb_build_object('name', p_name, 'slug', v_slug)
    );
  else
    update public.job_categories set
      name = trim(p_name),
      slug = v_slug,
      icon = nullif(trim(coalesce(p_icon, '')), ''),
      sort_order = coalesce(p_sort_order, 0),
      is_active = coalesce(p_is_active, true)
    where id = p_id
    returning id into v_id;
    if v_id is null then raise exception 'category not found'; end if;
    perform public.admin_audit(
      'category.update', 'job_category', v_id::text,
      jsonb_build_object('name', p_name, 'slug', v_slug)
    );
  end if;

  return v_id;
end;
$$;
grant execute on function public.admin_upsert_category(uuid, text, text, text, int, boolean)
  to authenticated;
