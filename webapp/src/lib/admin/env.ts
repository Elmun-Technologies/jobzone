import "server-only";

import { hasSupabase } from "@/lib/data/supabase-env";

/**
 * True when the admin panel's privileged reads can run: Supabase is configured
 * AND the server-only service-role key is present. When false (but anon env
 * exists) the panel still works in degraded mode — the dashboard RPC and all
 * mutations use the anon client; only cross-owner list screens need this.
 */
export function hasAdminSupabase(): boolean {
  return hasSupabase() && !!process.env.SUPABASE_SERVICE_ROLE_KEY;
}
