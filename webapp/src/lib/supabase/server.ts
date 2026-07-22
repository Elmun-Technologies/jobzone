import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

/**
 * Server-side Supabase client (Server Components, Route Handlers, Server
 * Actions). Reads/writes the auth session from cookies. The `setAll` try/catch
 * is required because Server Components cannot set cookies — the middleware
 * refreshes the session instead.
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Called from a Server Component — ignore; middleware will refresh.
          }
        },
      },
    },
  );
}

/**
 * Cookieless anon Supabase client for PUBLIC, user-independent reads (category
 * lists, city facets, company ratings). It reads no session, so it's safe to
 * call inside `unstable_cache` — which forbids request-scoped data like cookies
 * — letting those reference/aggregate reads be cached across all visitors
 * instead of hitting Postgres on every request. Never use this for
 * per-user/authenticated data; use `createClient()` for that.
 */
export function createPublicClient() {
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}
