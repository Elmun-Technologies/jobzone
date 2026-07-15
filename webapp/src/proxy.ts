import createMiddleware from "next-intl/middleware";
import { NextResponse, type NextRequest } from "next/server";

import { routing } from "@/i18n/routing";
import { isAdminUser } from "@/lib/auth/admin-role";
import { hasSupabase } from "@/lib/data/supabase-env";
import { updateSession } from "@/lib/supabase/middleware";

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
  const intlResponse = intlMiddleware(request);
  // Honor a locale redirect (e.g. "/" → "/uz") as-is.
  if (intlResponse.headers.has("location")) return intlResponse;

  const { response, user } = await updateSession(request, intlResponse);
  const path = request.nextUrl.pathname;

  // Without Supabase env the whole app (admin included) runs on mock data, so
  // /admin stays reachable for the offline demo instead of bouncing to sign-in.
  if (ADMIN.test(path) && !hasSupabase()) return response;

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
}

export const config = {
  // Skip Next internals, the OAuth callback (/auth/*), the Sentry tunnel
  // (/monitoring — locale-prefixing it breaks the tunnel route and every
  // client error report 404s), and files with an extension.
  matcher: ["/((?!api|auth|monitoring|_next|_vercel|.*\\..*).*)"],
};
