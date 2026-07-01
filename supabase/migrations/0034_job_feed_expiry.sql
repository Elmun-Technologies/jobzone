-- 0034_job_feed_expiry.sql
-- Hide expired postings from the seeker feed. Everything seekers read goes
-- through job_feed (both the web app and the mobile app, plus meili-reindex), so
-- filtering here enforces expiry everywhere at once. Employers still see their
-- expired jobs in the dashboard, which reads the jobs table directly.
-- Drop + recreate (not create-or-replace) to keep the j.* column order stable.
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
  left join public.job_categories cat on cat.id = j.category_id
  where j.expires_at is null or j.expires_at > now();
