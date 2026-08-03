/**
 * Is there a Supabase session cookie in this browser?
 *
 * The point is what it saves. Most of Yolla's traffic arrives from a search
 * result, reads one vacancy and never signs in, and asking Supabase "who is
 * this?" costs 244 KB of SDK to hear "nobody". The cookie's *presence* answers
 * that for free: no cookie, no session, no download.
 *
 * Presence only — never validity. An expired or forged cookie still gets the
 * full `getUser()` round trip, and every page that matters is gated on the
 * server regardless. This decides whether to ask, not what the answer is.
 *
 * `@supabase/ssr` writes `sb-<project-ref>-auth-token`, splitting it into
 * `.0`/`.1` chunks when it outgrows the cookie size limit — hence the loose
 * match on both ends rather than an exact name.
 */
const AUTH_COOKIE = /(?:^|;\s*)sb-[^=;]*auth-token[^=;]*=/;

export function hasAuthCookie(): boolean {
  try {
    return AUTH_COOKIE.test(document.cookie);
  } catch {
    // No document (or a locked-down context) — assume yes and let the real
    // check decide. Being wrong here costs a download, not correctness.
    return true;
  }
}

/**
 * Paths where a visitor can become signed in without a document load.
 *
 * The session provider skips loading Supabase for a cookieless visitor, which
 * would also mean skipping `onAuthStateChange` — so on these routes it loads
 * anyway and stays subscribed. It costs nothing: the sign-in forms on them
 * pull in the same SDK themselves.
 *
 * Everything else that can sign you in is already a document load — the Google
 * callback is a server redirect, and the "sign in to save / to apply" bounces
 * use `window.location`, so the provider is remounted with the cookie in place.
 */
const AUTH_ROUTES = new Set([
  "sign-in",
  "sign-up",
  "reset-password",
  "forgot-password",
]);

/**
 * Accepts the path with or without its locale prefix — `next/navigation`'s
 * `usePathname` gives `/uz/sign-in`, next-intl's gives `/sign-in` — by looking
 * at the first segment that isn't a two-letter locale.
 */
export function isAuthRoute(pathname: string): boolean {
  const segments = pathname.split("/").filter(Boolean);
  const first = segments[0];
  const head = first && /^[a-z]{2}$/.test(first) ? segments[1] : first;
  return head != null && AUTH_ROUTES.has(head);
}
