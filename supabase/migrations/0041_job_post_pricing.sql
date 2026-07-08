-- 0039_job_post_pricing.sql
-- Vacancy posting price: an employer's first published vacancy is free;
-- every one after that costs the 'job_post' catalog price (price lives in
-- promotion_products, not the app — same convention as boosts). Charged
-- from the company's Hamyon wallet via adjust_wallet(), a security-definer
-- RPC that lets the server action move a `completed` ledger row despite RLS
-- normally allowing clients only a `pending` topup insert (mirrors
-- apply_promotion()'s privileged-write pattern for boosts).

insert into public.promotion_products
  (code, name, description, kind, price_uzs, duration_days, sort_order) values
  ('job_post', 'Vakansiya joylash', 'Birinchi vakansiya bepul, keyingilari uchun to''lov', 'base', 99000, null, 6)
on conflict (code) do nothing;

-- Adjusts a company's wallet by a signed amount, inserting a `completed`
-- entry directly (RLS otherwise permits only a client-inserted pending
-- topup). Negative amounts (spend) are rejected if they would take the
-- balance below zero; the caller must own the company. Serializes
-- concurrent calls for the same company with an advisory lock so two
-- simultaneous spends (e.g. a double-submitted Publish) can't both pass the
-- balance check before either is recorded.
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
  if p_amount_uzs = 0 or p_kind not in ('spend', 'refund', 'bonus') then
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

  if p_amount_uzs < 0 and v_balance + p_amount_uzs < 0 then
    raise exception 'insufficient_funds';
  end if;

  insert into public.wallet_transactions
    (company_id, kind, amount_uzs, status, description, created_by, completed_at)
  values
    (p_company_id, p_kind, p_amount_uzs, 'completed', p_description, auth.uid(), now());

  return v_balance + p_amount_uzs;
end;
$$;

revoke all on function public.adjust_wallet(uuid, numeric, text, text) from public;
grant execute on function public.adjust_wallet(uuid, numeric, text, text) to authenticated;
