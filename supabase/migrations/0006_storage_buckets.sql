-- 0006_storage_buckets.sql
-- Storage buckets + access policies. Object paths are prefixed by the owning
-- entity id (e.g. `<auth.uid()>/avatar.png`) so policies can authorize by prefix.

insert into storage.buckets (id, name, public)
values
  ('avatars',          'avatars',          true),
  ('company-media',    'company-media',    true),
  ('intro-videos',     'intro-videos',     true),
  ('resumes',          'resumes',          false),
  ('chat-attachments', 'chat-attachments', false)
on conflict (id) do nothing;

-- Public-read buckets: anyone can read; owner (path prefix = auth.uid()) can write.
create policy "public buckets are readable"
  on storage.objects for select
  using (bucket_id in ('avatars','company-media','intro-videos'));

create policy "owner can write avatars/intro-videos"
  on storage.objects for all to authenticated
  using (
    bucket_id in ('avatars','intro-videos')
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id in ('avatars','intro-videos')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Company media: writable by the company owner (path prefix = company_id).
create policy "company owner can write company-media"
  on storage.objects for all to authenticated
  using (
    bucket_id = 'company-media'
    and exists (
      select 1 from public.companies c
      where c.id::text = (storage.foldername(name))[1] and c.owner_id = auth.uid()
    )
  )
  with check (
    bucket_id = 'company-media'
    and exists (
      select 1 from public.companies c
      where c.id::text = (storage.foldername(name))[1] and c.owner_id = auth.uid()
    )
  );

-- Resumes: private, owner-only (signed URLs for everything).
create policy "owner can manage own resumes"
  on storage.objects for all to authenticated
  using (bucket_id = 'resumes' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'resumes' and (storage.foldername(name))[1] = auth.uid()::text);

-- Chat attachments: private, readable/writable only by conversation participants.
-- Path convention: `<conversation_id>/<file>`.
create policy "participants can read chat attachments"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-attachments'
    and public.is_conversation_participant(((storage.foldername(name))[1])::uuid)
  );
create policy "participants can write chat attachments"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-attachments'
    and public.is_conversation_participant(((storage.foldername(name))[1])::uuid)
  );
