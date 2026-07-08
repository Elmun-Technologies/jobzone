import { NextResponse, type NextRequest } from "next/server";

import { safeNext } from "@/lib/auth/safe-next";
import { createClient } from "@/lib/supabase/server";

/**
 * OAuth / email-link callback. Exchanges the `code` for a session (sets the
 * auth cookies) and redirects to `next`. Lives outside the [locale] tree and
 * is excluded from the proxy matcher.
 */
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  // Only same-origin local paths — never an attacker-supplied off-site URL.
  const next = safeNext(searchParams.get("next"), "/uz/account");

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(`${origin}${next}`);
  }
  return NextResponse.redirect(`${origin}/uz/sign-in`);
}
