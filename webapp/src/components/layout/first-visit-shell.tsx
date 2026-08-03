"use client";

import { useEffect, useState } from "react";

import { ConsentBanner } from "@/components/consent/consent-banner";
import { LanguageSheet } from "@/components/layout/language-sheet";
import { CONSENT_COOKIE, parseConsent, type ConsentValue } from "@/lib/consent";
import { LOCALE_CHOICE_COOKIE, shouldAskLanguage } from "@/lib/locale-choice";

import { AnalyticsScripts } from "../analytics/analytics-scripts";

interface FirstVisit {
  consent: ConsentValue | null;
  askLanguage: boolean;
}

function readCookie(name: string): string | undefined {
  const m = new RegExp(`(?:^|; )${name}=([^;]*)`).exec(document.cookie);
  return m ? decodeURIComponent(m[1]) : undefined;
}

/**
 * Everything on the page that depends on who is asking and what they have
 * already answered: the cookie bar, the first-visit language sheet, and the
 * third-party analytics loaders those two gate.
 *
 * It reads all of it in the browser, and that is the whole point. Runtime data
 * read on the server during the layout's render makes the layout dynamic, and
 * a dynamic root layout makes *every* route in the app dynamic — a `<Suspense>`
 * boundary does not change that without PPR. Nothing here paints above the
 * fold (a bar pinned to the bottom, and a sheet only a mismatched first-time
 * visitor ever sees), so resolving it one tick after hydration costs nothing
 * visually and buys a prerendered page for everyone.
 *
 * The crawler guard that used to live in `shouldAskLanguage` is now mostly
 * moot in the direction that mattered: a bot that renders no JavaScript sees
 * no overlay at all, which is exactly what "no intrusive interstitial" means.
 * It is still passed, for the bots that do run scripts.
 */
export function FirstVisitShell({ locale }: { locale: string }) {
  const [visit, setVisit] = useState<FirstVisit | null>(null);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setVisit({
      consent: parseConsent(readCookie(CONSENT_COOKIE)),
      askLanguage: shouldAskLanguage({
        current: locale,
        chosen: readCookie(LOCALE_CHOICE_COOKIE),
        // `navigator.languages` is the browser's own ranked list — the same
        // preference order Accept-Language encodes, minus the q-values, and
        // `preferredFromHeader` already keeps list order for equal quality.
        acceptLanguage:
          navigator.languages?.join(",") ?? navigator.language ?? null,
        userAgent: navigator.userAgent,
      }),
    });
  }, [locale]);

  if (!visit) return null;

  return (
    <>
      {visit.askLanguage ? <LanguageSheet /> : null}
      <ConsentBanner
        initialConsent={visit.consent}
        deferred={visit.askLanguage}
        onChoice={(value) => setVisit({ ...visit, consent: value })}
      />
      {visit.consent === "granted" ? <AnalyticsScripts /> : null}
    </>
  );
}
