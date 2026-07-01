import "server-only";

import {
  createClient as createSupabaseClient,
  type SupabaseClient,
} from "@supabase/supabase-js";

/**
 * Service-role Supabase client for admin panel reads (list screens must see
 * across owners, which RLS forbids for the anon client). Cookie-free and
 * session-less — it must only ever be used server-side, after `requireAdmin()`
 * has vouched for the caller; never import it outside `src/lib/admin/**`.
 * Admin mutations do NOT use it: they go through `is_admin()`-gated definer
 * RPCs on the normal anon client so the DB re-checks the actor.
 *
 * Returns null when the key isn't configured (local dev / preview) — callers
 * degrade to mock or empty data, never throw at module scope.
 */
export function createAdminClient(): SupabaseClient | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  return createSupabaseClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
