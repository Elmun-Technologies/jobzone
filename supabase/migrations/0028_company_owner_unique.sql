-- 0028_company_owner_unique.sql
-- One company per owner. The employer area assumes a single company per
-- owner_id (CompanyAdminRepository.myCompany() does .maybeSingle()); without
-- this, a double-create bricked the dashboard/people/gallery with no recovery.
-- createCompany() is now idempotent (re-fetches first); this partial unique
-- index is the server-side backstop.
--
-- If this fails because pre-existing duplicate owners exist (from the bug),
-- delete the extra company rows for the affected owner(s), then re-run.
create unique index if not exists companies_owner_id_key
  on public.companies (owner_id)
  where owner_id is not null;
