/**
 * Whether the visitor has ever picked a language themselves.
 *
 * `localePrefix: "always"` means the URL decides which locale renders, and the
 * default (`uz`) is what an inbound link or a Google result gives everyone —
 * including the large Russian-reading share of this market, who then land on a
 * page they can't read and have to find a two-letter pill in the header to fix
 * it. This cookie records an explicit choice (from the first-visit sheet or
 * the header switcher) so the sheet is shown exactly once and never again.
 *
 * Deliberately separate from `profiles.preferred_locale`: that only exists for
 * signed-in users, and the visitor who most needs the prompt is a guest.
 */
export const LOCALE_CHOICE_COOKIE = "yolla-locale-chosen";

/** One year — a language choice is not a session-scoped decision. */
export const LOCALE_CHOICE_MAX_AGE = 60 * 60 * 24 * 365;

/**
 * Fired on `window` when the first-visit sheet closes (picked or dismissed).
 * The cookie banner waits for it before showing itself — see ConsentBanner.
 */
export const LANGUAGE_CHOSEN_EVENT = "yolla:language-chosen";

/** Client-side write, used by both the sheet and the header switcher. */
export function rememberLocaleChoice(locale: string): void {
  document.cookie = `${LOCALE_CHOICE_COOKIE}=${locale}; Path=/; Max-Age=${LOCALE_CHOICE_MAX_AGE}; SameSite=Lax`;
}

const SUPPORTED = ["uz", "ru", "en"] as const;

/**
 * The visitor's own top-ranked language among the three we serve, from the
 * `Accept-Language` header — or null when the header carries no usable signal.
 * Matching is on the primary subtag, so `ru-RU`, `uz-Latn-UZ` and `en-GB` all
 * resolve.
 */
export function preferredFromHeader(header: string | null): string | null {
  if (!header) return null;
  const ranked = header
    .split(",")
    .map((part) => {
      const [tag, ...params] = part.trim().split(";");
      const q = params
        .map((p) => p.trim())
        .find((p) => p.startsWith("q="))
        ?.slice(2);
      return { tag: tag.trim().toLowerCase(), q: q ? Number(q) : 1 };
    })
    .filter((e) => e.tag && Number.isFinite(e.q) && e.q > 0)
    // Stable sort by descending quality, so equal-q tags keep header order.
    .sort((a, b) => b.q - a.q);
  for (const { tag } of ranked) {
    const primary = tag.split("-")[0];
    if ((SUPPORTED as readonly string[]).includes(primary)) return primary;
  }
  return null;
}

// Rendered HTML is what a crawler indexes, and an overlay covering the page on
// first view is exactly what "intrusive interstitial" means to a search engine
// — on a marketplace whose main channel is organic search, that is not a risk
// worth taking for a prompt no crawler can answer anyway.
const CRAWLER = /bot|crawl|spider|slurp|yandex|facebookexternalhit|preview/i;

/**
 * Whether to show the first-visit language sheet.
 *
 * Deliberately narrower than the local apps that inspired it, which ask every
 * first-time visitor: we ask only the visitor whose own browser language is
 * one we serve and is *not* the one they are looking at — the person who
 * landed on a deep link (a search result, a shared vacancy) in a language they
 * may not read. Everyone else, including anyone who already chose, is left
 * alone.
 */
export function shouldAskLanguage({
  current,
  chosen,
  acceptLanguage,
  userAgent,
}: {
  current: string;
  chosen: string | undefined;
  acceptLanguage: string | null;
  userAgent: string | null;
}): boolean {
  if (chosen) return false;
  if (userAgent && CRAWLER.test(userAgent)) return false;
  const preferred = preferredFromHeader(acceptLanguage);
  return preferred !== null && preferred !== current;
}
