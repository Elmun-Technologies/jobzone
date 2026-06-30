import { createServerClient } from "@supabase/ssr";
import type { User } from "@supabase/supabase-js";
import type { NextRequest, NextResponse } from "next/server";

/**
 * Refreshes the Supabase auth session on each request, writing any rotated
 * cookies onto the (already locale-resolved) response from next-intl, and
 * returns the current user so the proxy can gate routes.
 *
 * No-ops gracefully when Supabase env vars are absent (local/dev/preview
 * without credentials) — mirroring the Flutter app's `Env.hasSupabase` gate.
 */
export async function updateSession(
  request: NextRequest,
  response: NextResponse,
): Promise<{ response: NextResponse; user: User | null }> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return { response, user: null };

  const supabase = createServerClient(url, key, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value, options }) =>
          response.cookies.set(name, value, options),
        );
      },
    },
  });

  // Touch the session so expired tokens are refreshed into the response cookies.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return { response, user };
}
