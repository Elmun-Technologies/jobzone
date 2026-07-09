-- 0053_admin_categories.sql
-- Admin-editable job-category taxonomy: lets the technical team add, edit, or
-- retire a category from the panel instead of a migration + deploy. Builds on
-- the admin foundation (0037: is_admin(), admin_audit()) — job_categories
-- previously had no write policy for anyone.

alter table public.job_categories
  add column if not exists is_active boolean not null default true,
  add column if not exists sort_order int not null default 0;

-- ---------------------------------------------------------------------------
-- Insert or update a category. p_id null -> insert; existing p_id -> update
-- in place. Admin-only, security definer (job_categories has no client write
-- policy — see 0002_jobs_companies.sql).
-- ---------------------------------------------------------------------------
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
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if coalesce(trim(p_name), '') = '' or coalesce(trim(p_slug), '') = '' then
    raise exception 'name and slug are required';
  end if;

  if p_id is null then
    insert into public.job_categories (name, slug, icon, sort_order, is_active)
    values (
      trim(p_name), trim(p_slug), nullif(trim(coalesce(p_icon, '')), ''),
      coalesce(p_sort_order, 0), coalesce(p_is_active, true)
    )
    returning id into v_id;
    perform public.admin_audit(
      'category.create', 'job_category', v_id::text,
      jsonb_build_object('name', p_name, 'slug', p_slug)
    );
  else
    update public.job_categories set
      name = trim(p_name),
      slug = trim(p_slug),
      icon = nullif(trim(coalesce(p_icon, '')), ''),
      sort_order = coalesce(p_sort_order, 0),
      is_active = coalesce(p_is_active, true)
    where id = p_id
    returning id into v_id;
    if v_id is null then raise exception 'category not found'; end if;
    perform public.admin_audit(
      'category.update', 'job_category', v_id::text,
      jsonb_build_object('name', p_name, 'slug', p_slug)
    );
  end if;

  return v_id;
end;
$$;
grant execute on function public.admin_upsert_category(uuid, text, text, text, int, boolean)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Toggle a category active/inactive without touching its other fields —
-- pickers/browse grids read only is_active = true, so this retires a category
-- without deleting it (jobs already posted under it are unaffected).
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_category_active(p_id uuid, p_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  update public.job_categories set is_active = p_active where id = p_id;
  if not found then raise exception 'category not found'; end if;
  perform public.admin_audit(
    'category.set_active', 'job_category', p_id::text,
    jsonb_build_object('active', p_active)
  );
end;
$$;
grant execute on function public.admin_set_category_active(uuid, boolean) to authenticated;
