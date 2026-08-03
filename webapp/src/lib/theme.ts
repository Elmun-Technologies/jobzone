/**
 * Light/dark theme — chosen by the visitor, applied before first paint.
 *
 * History matters here, because this has been round-tripped twice. It started
 * in `localStorage`, applied by an inline script. That broke on a language
 * switch: the switch was a client navigation, React re-rendered `<html>` from
 * the RSC payload, and a class only JS had added was dropped — the page turned
 * white mid-session. The fix was to move the choice into a cookie so the root
 * layout could render the class itself.
 *
 * That fix worked, and it cost the entire site its static shell: a layout that
 * reads a cookie is dynamic, and a dynamic root layout makes every route in the
 * app dynamic, so nothing could be served from the CDN and every visit paid for
 * a serverless render. The trade is not worth it for a preference toggle.
 *
 * So the class is applied by the inline script again — and the language switch
 * is now a document load (see lib/locale-nav.ts), which is what makes that
 * safe: the script runs on every load, so the theme survives the one navigation
 * that used to lose it. Verified both ways in a browser.
 *
 * The cookie is still written. Nothing on the server reads it today; it is kept
 * because it costs nothing and any future non-JS surface (an email preview, a
 * WebView) can read the choice without guessing.
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
