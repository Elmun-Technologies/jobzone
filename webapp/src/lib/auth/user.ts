import "server-only";

import type { User } from "@supabase/supabase-js";
import { cache } from "react";

import { hasSupabase } from "@/lib/data/supabase-env";
import { createClient } from "@/lib/supabase/server";

/**
 * The signed-in Supabase user, or null. Memoized per request so the header and
 * page can both call it without a double round-trip.
 */
export const getCurrentUser = cache(async (): Promise<User | null> => {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    return user;
  } catch {
    return null;
  }
});
