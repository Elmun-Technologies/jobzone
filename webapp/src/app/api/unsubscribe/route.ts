import { NextResponse, type NextRequest } from "next/server";

import { createClient as createSupabaseClient } from "@supabase/supabase-js";

import { hasSupabase } from "@/lib/data/supabase-env";
import { isUnsubscribeToken, parseScope } from "@/lib/email-scopes";

/**
 * One-click unsubscribe (RFC 8058). Every marketing/alert email carries
 *
 *   List-Unsubscribe: <https://…/api/unsubscribe?token=…&scope=…>, <page URL>
 *   List-Unsubscribe-Post: List-Unsubscribe=One-Click
 *
 * and Gmail/Yahoo POST here when the reader taps their client's own
 * "unsubscribe" affordance — no page, no session, no confirmation step. Having
 * this actually work is a bulk-sender requirement at both providers; failing it
 * is how a sending domain ends up in spam.
 *
 * The token (a uuid minted per profile in migration 0084) is the entire
 * authorization, and the RPC behind it can do exactly one thing: switch that
 * profile's email categories off. GET is a courtesy redirect to the human page
 * — mail scanners follow links, so a GET must never change anything.
 *
 * Lives outside the [locale] tree and is excluded from the proxy matcher.
 */
export async function POST(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const token = (searchParams.get("token") ?? "").trim();
  const scope = parseScope(searchParams.get("scope"));

  if (!isUnsubscribeToken(token)) {
    return new NextResponse("invalid token", { status: 400 });
  }
  if (!hasSupabase()) {
    return new NextResponse("unavailable", { status: 503 });
  }

  try {
    const supabase = createSupabaseClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { error } = await supabase.rpc("set_email_pref_by_token", {
      p_token: token,
      p_scope: scope,
      p_enabled: false,
    });
    if (error) {
      // An unknown token still gets a 200: the mail client shows the reader a
      // failure banner otherwise, and there is nothing they could do about it.
      // The log is where a real problem surfaces.
      if (error.code !== "P0002") {
        console.error("one-click unsubscribe failed", error.message);
      }
    }
  } catch (e) {
    console.error("one-click unsubscribe threw", e);
  }

  return new NextResponse("unsubscribed", { status: 200 });
}

/** A click on the link (rather than the client's button) lands on the page. */
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const token = (searchParams.get("token") ?? "").trim();
  const scope = parseScope(searchParams.get("scope"));
  const query = new URLSearchParams({ scope });
  if (isUnsubscribeToken(token)) query.set("token", token);
  return NextResponse.redirect(
    new URL(`/uz/unsubscribe?${query.toString()}`, origin),
  );
}
