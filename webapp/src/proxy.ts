import createMiddleware from "next-intl/middleware";
import { NextResponse, type NextRequest } from "next/server";

import { routing } from "@/i18n/routing";
import { updateSession } from "@/lib/supabase/middleware";

// Next.js 16 renamed Middleware → Proxy. The handler runs locale routing first
// (may redirect `/` → `/uz`), refreshes the Supabase session cookies, then
// gates authenticated routes (optimistic check — secure checks live in the
// pages/actions themselves).
const intlMiddleware = createMiddleware(routing);

const LOCALE = "(?:uz|ru|en)";
const PROTECTED = new RegExp(`^/${LOCALE}/(?:account|employer)(?:/|$)`);
const AUTH_PAGES = new RegExp(`^/${LOCALE}/(?:sign-in|sign-up)(?:/|$)`);

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

  if (!user && PROTECTED.test(path)) {
    const url = new URL(`/${localeOf(path)}/sign-in`, request.url);
    url.searchParams.set("next", path);
    return NextResponse.redirect(url);
  }
  if (user && AUTH_PAGES.test(path)) {
    return NextResponse.redirect(
      new URL(`/${localeOf(path)}/account`, request.url),
    );
  }

  return response;
}

export const config = {
  // Skip Next internals, the OAuth callback (/auth/*), and files with an extension.
  matcher: ["/((?!api|auth|_next|_vercel|.*\\..*).*)"],
};
