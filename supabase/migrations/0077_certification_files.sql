-- 0077: let a seeker attach the actual certificate file, not just describe it.
--
-- `certifications` (0001) records what the certificate says — name, issuer,
-- credential id, dates — plus `credential_url`, a link to a verifier page.
-- That covers a Coursera or a Google cert, whose issuer hosts a public
-- verification URL. It covers almost nothing in this market: a welding
-- qualification, a forklift licence, a food-handling card, a driving
-- category, a college diploma — these exist as a photo or a PDF in the
-- holder's hand, with no issuer website to link to. So the field that
-- mattered most to a blue-collar applicant had nowhere to go, and an
-- employer had to take the claim on trust.
--
-- Mirrors `resumes` exactly (file_path / file_size / mime_type) so both
-- clients reuse the upload path they already have, and adds the matching
-- private bucket.
--
-- Nullable: a certificate with only a verification link stays valid, and
-- every existing row keeps working untouched.

alter table public.certifications
  add column if not exists file_path text,   -- storage key in `certificates`
  add column if not exists file_size bigint,
  add column if not exists mime_type text;

-- Private, like `resumes` — a diploma carries a full name and often a
-- passport or birth date. Everything is served through signed URLs.
insert into storage.buckets (id, name, public)
values ('certificates', 'certificates', false)
on conflict (id) do nothing;

-- Path convention `<auth.uid()>/<file>`, same as resumes/avatars, so the
-- owner check is a folder-prefix comparison.
drop policy if exists "owner can manage own certificates" on storage.objects;
create policy "owner can manage own certificates"
  on storage.objects for all to authenticated
  using (
    bucket_id = 'certificates'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'certificates'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- A recruiter may read a candidate's certificate only when that candidate
-- actually applied to one of the recruiter's jobs — the same gate 0049 put
-- on the `certifications` row itself (`is_recruiter_of`). Without this the
-- employer could read the certificate's *description* but not open the
-- document it describes, which is the whole point of attaching one.
drop policy if exists "recruiter can read applicant certificates" on storage.objects;
create policy "recruiter can read applicant certificates"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'certificates'
    and public.is_recruiter_of(((storage.foldername(name))[1])::uuid)
  );
