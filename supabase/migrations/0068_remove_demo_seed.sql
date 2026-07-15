-- 0068: purge the seed_dev.sql demo content from any database it was ever
-- applied to (the product is online-only now — no demo rows may exist).
--
-- Targets exactly the two fixed-UUID companies seed_dev.sql inserted ('Acme'
-- and 'Nimbus'); the slug guard makes the delete a no-op if those UUIDs were
-- never seeded. Their jobs, applications, bookmarks, reviews, follows and
-- wallet rows go with them via the existing ON DELETE CASCADE / SET NULL
-- foreign keys. Idempotent — safe on databases that never saw seed_dev.

delete from public.companies
where id in (
        '00000000-0000-0000-0000-0000000ac3e0', -- Acme
        '00000000-0000-0000-0000-00000001b005'  -- Nimbus
      )
  and slug in ('acme', 'nimbus');
