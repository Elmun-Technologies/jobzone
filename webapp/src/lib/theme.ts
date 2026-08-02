/**
 * Light/dark theme — stored in a cookie so the **server** renders it.
 *
 * It used to live in `localStorage` alone, applied by an inline script that
 * added a `dark` class to <html> before first paint. That works on a hard load
 * and nowhere else: switching language is a client-side navigation, React
 * re-renders <html> from the RSC payload — which has no `dark` in it, because
 * the class was added imperatively — and the class is dropped. The page turned
 * white mid-session and only a refresh brought the theme back. Next's own guide
 * says as much: "Scripts inserted via DOM updates don't execute in the browser.
 * On client-side navigations, React renders the component from the RSC payload
 * and the script won't run."
 *
 * With the choice in a cookie the root layout puts `dark` in the markup itself,
 * so it is part of every payload and survives any navigation. The inline script
 * stays for exactly one job: the first visit, where there is no cookie yet and
 * only the browser knows the OS preference — it applies it and writes the
 * cookie, so from then on the server is the one deciding.
 *
 * Strictly functional: a UI preference the visitor set themselves, no
 * identifier, nothing sent to a third party — so it sits outside the analytics
 * consent gate, like the language prefix in the URL.
 */

export const THEME_COOKIE = "theme";
export type ThemeValue = "dark" | "light";

/** One year — the same horizon as the consent cookie. */
export const THEME_MAX_AGE_SECONDS = 60 * 60 * 24 * 365;

export function parseTheme(raw: string | undefined | null): ThemeValue | null {
  if (raw === "dark" || raw === "light") return raw;
  return null;
}

/** The `document.cookie` string both the toggle and the inline script write. */
export function themeCookieString(value: ThemeValue): string {
  return `${THEME_COOKIE}=${value};path=/;max-age=${THEME_MAX_AGE_SECONDS};SameSite=Lax`;
}
