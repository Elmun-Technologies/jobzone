# Verification guard — manual SQL checks

The Flutter test suite runs against the offline mock and cannot exercise
Postgres RLS / triggers. Verification (migration `0016`) is security-sensitive —
a user must **never** be able to self-verify. Run these against a database with
the migrations applied (`supabase db reset`, or the live project via SQL editor)
to confirm the guard. Each `EXPECT` describes the required outcome.

## Companies — owner cannot self-verify
```sql
-- As a normal authenticated owner (not admin):
update public.companies set is_verified = true,
       verification_method = 'legal_entity'
 where id = '<my-company>';
select is_verified, verification_method from public.companies where id = '<my-company>';
-- EXPECT: is_verified = false, verification_method = null  (guard reverted them)
```

## Profiles — user cannot self-verify
```sql
update public.profiles
   set worker_verified_at = now(), phone_verified_at = now()
 where id = auth.uid();
select worker_verified_at, phone_verified_at from public.profiles where id = auth.uid();
-- EXPECT: both null  (guard reverted them)
```

## Admin grant works
```sql
-- With a JWT whose app_metadata.role = 'admin' (or service role + is_admin shim):
select public.admin_set_company_verification('<company>', 'legal_entity');
select is_verified, verified_by, verification_method
  from public.companies where id = '<company>';
-- EXPECT: is_verified = true, verified_by = admin uid, method = 'legal_entity'

select public.admin_set_company_verification('<company>', 'legal_entity'); -- as non-admin
-- EXPECT: ERROR 'admin only'
```

## Phone confirm is gated
```sql
select public.confirm_phone();   -- when auth.users.phone_confirmed_at IS NULL
-- EXPECT: ERROR 'phone not confirmed'
-- After Supabase Auth confirms the phone, confirm_phone() sets phone_verified_at.
```

## Projection
```sql
select phone_verified, worker_verified from public.profiles_public limit 1;
-- EXPECT: booleans, no raw timestamps exposed.
```
