import { NextResponse, type NextRequest } from "next/server";

import type { EmailOtpType } from "@supabase/supabase-js";

import { safeNext } from "@/lib/auth/safe-next";
import { createClient } from "@/lib/supabase/server";

// Email-link verification types Supabase can send to `?token_hash=…&type=…`.
const EMAIL_OTP_TYPES: readonly string[] = [
  "signup",
  "invite",
  "magiclink",
  "recovery",
  "email_change",
  "email",
];

/**
 * OAuth / email-link callback. Exchanges the `code` (or verifies a
 * `token_hash` from an email link) for a session (sets the auth cookies) and
 * redirects to `next`. Lives outside the [locale] tree and is excluded from
 * the proxy matcher.
 *
 * Failures redirect back to sign-in with `?error=oauth` (keeping the caller's
 * locale and `next`) and log the underlying reason — a silent bounce here
 * looks like the page "just reloaded" and made misconfiguration (redirect URL
 * not allowlisted, provider secret wrong, host mismatch dropping the PKCE
 * cookie) undiagnosable in production.
 */
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const tokenHash = searchParams.get("token_hash");
  const otpType = searchParams.get("type");
  // Only same-origin local paths — never an attacker-supplied off-site URL.
  const rawNext = searchParams.get("next");
  const next = safeNext(rawNext, "/uz/account");

  // Keep the user's locale on the failure path ("/ru/…" → "/ru/sign-in").
  const locale = /^\/(uz|ru|en)(?:\/|$)/.exec(next)?.[1] ?? "uz";
  const signInUrl = new URL(`${origin}/${locale}/sign-in`);
  signInUrl.searchParams.set("error", "oauth");
  if (rawNext) signInUrl.searchParams.set("next", next);

  // Provider-reported failure (user cancelled consent, provider misconfig…).
  const providerError =
    searchParams.get("error_description") ?? searchParams.get("error");
  if (providerError) {
    console.error("auth callback: provider returned error:", providerError);
    return NextResponse.redirect(signInUrl);
  }

  const supabase = await createClient();

  // Email-link verification (confirmation / recovery / magic link). Unlike
  // the PKCE `code` exchange this needs no verifier cookie, so it also works
  // when the email is opened in a different browser or on another device.
  if (tokenHash && otpType && EMAIL_OTP_TYPES.includes(otpType)) {
    const { error } = await supabase.auth.verifyOtp({
      type: otpType as EmailOtpType,
      token_hash: tokenHash,
    });
    if (error) {
      console.error("auth callback: otp verify failed:", error.message);
      return NextResponse.redirect(signInUrl);
    }
    return NextResponse.redirect(`${origin}${next}`);
  }

  if (!code) {
    console.error("auth callback: hit without a code param");
    return NextResponse.redirect(signInUrl);
  }

  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) {
    console.error("auth callback: code exchange failed:", error.message);
    return NextResponse.redirect(signInUrl);
  }
  return NextResponse.redirect(`${origin}${next}`);
}
