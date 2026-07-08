-- 0042_wallet_and_job_ownership_guard.sql
-- Two authorization fixes surfaced by the security audit:
--   1. adjust_wallet() let an employer MINT balance. It is security-definer,
--      granted to authenticated, and only checked company ownership + that
--      p_kind was one of ('spend','refund','bonus') — never the sign. So an
--      owner could call adjust_wallet(my_company, +100000000, 'bonus') to
--      insert a `completed` credit and post paid vacancies/boosts for free.
--      Fix: authenticated callers may ONLY spend (a negative debit). Credits
--      (topup completion, refunds, bonuses) are service-role only.
--   2. The jobs INSERT/UPDATE with-check passed on `posted_by = auth.uid()`
--      alone, ignoring company_id — so a crafted submit could post a job under
--      ANY company (brand/verified-badge spoofing). Fix: writes require the
--      caller to own the target company.

-- ---------------------------------------------------------------------------
-- 1. adjust_wallet: spend-only for authenticated callers.
-- ---------------------------------------------------------------------------
create or replace function public.adjust_wallet(
  p_company_id uuid,
  p_amount_uzs numeric,
  p_kind text,
  p_description text default null
) returns numeric
language plpgsql security definer set search_path = public as $$
declare
  v_balance numeric;
begin
  -- Only a real debit is allowed through this RPC. A credit (positive amount,
  -- or refund/bonus/topup kinds) must come from the service role directly, so
  -- a client can never mint balance.
  if p_kind <> 'spend' or p_amount_uzs >= 0 then
    raise exception 'invalid_amount';
  end if;
  if not exists (
    select 1 from public.companies
    where id = p_company_id and owner_id = auth.uid()
  ) then
    raise exception 'not_owner';
  end if;

  perform pg_advisory_xact_lock(hashtext(p_company_id::text));

  select coalesce(sum(amount_uzs), 0) into v_balance
    from public.wallet_transactions
    where company_id = p_company_id and status = 'completed';

  if v_balance + p_amount_uzs < 0 then
    raise exception 'insufficient_funds';
  end if;

  insert into public.wallet_transactions
    (company_id, kind, amount_uzs, status, description, created_by, completed_at)
  values
    (p_company_id, 'spend', p_amount_uzs, 'completed', p_description, auth.uid(), now());

  return v_balance + p_amount_uzs;
end;
$$;

revoke all on function public.adjust_wallet(uuid, numeric, text, text) from public;
grant execute on function public.adjust_wallet(uuid, numeric, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. jobs writes require company ownership (no posting under other companies).
--    SELECT/DELETE stay lenient (poster OR owner) for read/cleanup, but the
--    INSERT/UPDATE with-check now demands ownership of the target company AND
--    self-attribution.
-- ---------------------------------------------------------------------------
drop policy if exists "jobs full access for poster" on public.jobs;
create policy "jobs full access for poster"
  on public.jobs for all to authenticated
  using (
    auth.uid() = posted_by
    or exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = auth.uid()
    )
  )
  with check (
    posted_by = auth.uid()
    and exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = auth.uid()
    )
  );
