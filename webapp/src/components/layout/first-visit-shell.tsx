import { cookies, headers } from "next/headers";

import { ConsentBanner } from "@/components/consent/consent-banner";
import { LanguageSheet } from "@/components/layout/language-sheet";
import { CONSENT_COOKIE, parseConsent } from "@/lib/consent";
import { LOCALE_CHOICE_COOKIE, shouldAskLanguage } from "@/lib/locale-choice";

import { AnalyticsScripts } from "../analytics/analytics-scripts";

/**
 * Everything on the page that depends on who is asking and what they have
 * already answered: the cookie bar, the first-visit language sheet, and the
 * third-party analytics loaders those two gate.
 *
 * It lives in one component so the root layout does not have to touch
 * `cookies()` or `headers()` itself. That distinction is the whole point —
 * runtime data read in the layout makes the layout dynamic, and a dynamic root
 * layout makes every route in the app dynamic. Read inside a `<Suspense>`
 * boundary instead, it is a hole in an otherwise static shell: the page ships
 * from the CDN and this streams in behind it.
 *
 * Nothing here paints above the fold — a banner pinned to the bottom and a
 * sheet that only a mismatched first-time visitor ever sees — so streaming it
 * a beat late costs nothing visually.
 */
export async function FirstVisitShell({ locale }: { locale: string }) {
  const cookieStore = await cookies();
  const consent = parseConsent(cookieStore.get(CONSENT_COOKIE)?.value);
  const headerBag = await headers();
  const askLanguage = shouldAskLanguage({
    current: locale,
    chosen: cookieStore.get(LOCALE_CHOICE_COOKIE)?.value,
    acceptLanguage: headerBag.get("accept-language"),
    userAgent: headerBag.get("user-agent"),
  });

  return (
    <>
      {askLanguage ? <LanguageSheet /> : null}
      <ConsentBanner initialConsent={consent} deferred={askLanguage} />
      {consent === "granted" ? <AnalyticsScripts /> : null}
    </>
  );
}
