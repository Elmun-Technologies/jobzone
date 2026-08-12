import { routing, type Locale } from "@/i18n/routing";

/**
 * Switching language is a full page load, on purpose.
 *
 * It used to be a client navigation (`router.replace` with a locale), and that
 * choice quietly dictated the rest of the app's architecture: React re-renders
 * `<html>` from the RSC payload on a client navigation, so the dark-mode class
 * had to be in the server's markup — which meant the root layout had to read a
 * cookie, which meant every route in the app was dynamic and nothing could be
 * served from the CDN.
 *
 * A document load costs one navigation (rare — most visitors change language
 * once, if ever) and buys back the static shell, because the pre-paint script
 * runs again and applies the theme itself. Verified both ways in a browser: a
 * client-side switch drops a JS-applied `dark` class, a full load keeps it.
 *
 * Everything that made the client version careful is preserved here — the
 * query string rides along, and callers park their in-progress forms first.
 */
export function localeHref(nextLocale: Locale, pathname: string): string {
  // `pathname` comes from next-intl's usePathname: locale-stripped, no query.
  const path = pathname.startsWith("/") ? pathname : `/${pathname}`;
  const search = typeof window === "undefined" ? "" : window.location.search;
  const hash = typeof window === "undefined" ? "" : window.location.hash;
  return `/${nextLocale}${path === "/" ? "" : path}${search}${hash}`;
}

/** Navigates to `next`, keeping the current path, query and hash. */
export function goToLocale(nextLocale: Locale, pathname: string): void {
  if (!routing.locales.includes(nextLocale)) return;
  window.location.assign(localeHref(nextLocale, pathname));
}
