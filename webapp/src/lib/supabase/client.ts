import { createBrowserClient } from "@supabase/ssr";

/**
 * Browser-side Supabase client (Client Components). Uses the public anon key;
 * all access is enforced by Postgres RLS. Typed `Database` generics are added
 * in a later phase via `supabase gen types typescript`.
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
