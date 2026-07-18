import createMiddleware from "next-intl/middleware";
import { NextResponse, type NextRequest } from "next/server";

import { routing } from "@/i18n/routing";
import { isAdminUser } from "@/lib/auth/admin-role";
import { updateSession } from "@/lib/supabase/middleware";
import { siteUrl } from "@/lib/seo";

// Next.js 16 renamed Middleware → Proxy. The handler runs locale routing first
// (may redirect `/` → `/uz`), refreshes the Supabase session cookies, then
// gates authenticated routes (optimistic check — secure checks live in the
// pages/actions themselves).
const intlMiddleware = createMiddleware(routing);

const LOCALE = "(?:uz|ru|en)";
// Web is guest-first: a visitor can browse and *start* the seeker/employer
// flows without a login — auth is asked for only at the last step (save
// résumé, submit an application, publish a job), handled in each action +
// form. The account hub and the rest of the employer area stay gated.
const PROTECTED = new RegExp(`^/${LOCALE}/(?:account|employer|admin)(?:/|$)`);
const GUEST_OK = new RegExp(`^/${LOCALE}/employer/jobs/new(?:/|$)`);
const AUTH_PAGES = new RegExp(`^/${LOCALE}/(?:sign-in|sign-up)(?:/|$)`);
// Technical-team-only panel: optimistic non-admin bounce here; the secure,
// invisible check is requireAdmin()'s notFound() in every admin page.
const ADMIN = new RegExp(`^/${LOCALE}/admin(?:/|$)`);

function localeOf(path: string): string {
  const seg = path.split("/")[1];
  return routing.locales.includes(seg as never) ? seg : routing.defaultLocale;
}

export async function proxy(request: NextRequest) {
  // Self-canonicalize: the production deployment stays reachable on its
  // *.vercel.app URLs (old indexed links, pre-domain emails, stale tabs).
  // A session started there lives on the wrong origin — the user signs in
  // on vercel.app, then looks signed out on the brand domain. Bounce every
  // production vercel.app request onto the canonical host before anything
  // else runs. Previews (VERCEL_ENV=preview) keep their vercel.app URLs.
  const host = request.headers.get("host") ?? "";
  if (process.env.VERCEL_ENV === "production" && host.endsWith(".vercel.app")) {
    const canonical = new URL(request.url);
    canonical.protocol = "https:";
    canonical.host = new URL(siteUrl()).host;
    canonical.port = "";
    return NextResponse.redirect(canonical, 308);
  }

  const intlResponse = intlMiddleware(request);
  // Honor a locale redirect (e.g. "/" → "/uz") as-is.
  if (intlResponse.headers.has("location")) return intlResponse;

  // Fail OPEN: this is a guest-first marketplace, so the middleware must
  // never take the whole site down. If the session refresh throws (a
  // Supabase blip, a malformed auth cookie, an edge-runtime hiccup), serve
  // the page as a guest — the protected pages re-check auth server-side via
  // getCurrentUser()/requireAdmin() anyway, so security doesn't depend on
  // this optimistic gate. Without this, any throw here becomes a
  // MIDDLEWARE_INVOCATION_FAILED 500 on EVERY route.
  try {
    const { response, user } = await updateSession(request, intlResponse);
    const path = request.nextUrl.pathname;

    if (!user && PROTECTED.test(path) && !GUEST_OK.test(path)) {
      const url = new URL(`/${localeOf(path)}/sign-in`, request.url);
      url.searchParams.set("next", path);
      return NextResponse.redirect(url);
    }
    if (user && ADMIN.test(path) && !isAdminUser(user)) {
      return NextResponse.redirect(new URL(`/${localeOf(path)}`, request.url));
    }
    if (user && AUTH_PAGES.test(path)) {
      return NextResponse.redirect(
        new URL(`/${localeOf(path)}/account`, request.url),
      );
    }

    return response;
  } catch {
    // Degrade to a guest response rather than 500 the entire site.
    return intlResponse;
  }
}

export const config = {
  // Skip Next internals, the OAuth callback (/auth/*), the Sentry tunnel
  // (/monitoring — locale-prefixing it breaks the tunnel route and every
  // client error report 404s), and files with an extension.
  matcher: ["/((?!api|auth|monitoring|_next|_vercel|.*\\..*).*)"],
};
