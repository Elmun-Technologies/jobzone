"use client";

import { useTranslations } from "next-intl";
import { useEffect, useState } from "react";

import { Link } from "@/i18n/navigation";
import {
  CONSENT_COOKIE,
  CONSENT_MAX_AGE_SECONDS,
  type ConsentValue,
} from "@/lib/consent";
import { LANGUAGE_CHOSEN_EVENT } from "@/lib/locale-choice";

/**
 * Cookie banner. `FirstVisitShell` reads the cookie in the browser and
 * forwards it here as `initialConsent`; if that's null (visitor hasn't chosen
 * yet) we mount the sticky bar. When the visitor clicks accept/reject we
 * persist to the cookie AND to localStorage so the mobile app's WebView (if we
 * ever add one) can inherit the choice, then report the choice upward so the
 * analytics loaders mount immediately. This used to reload the page instead —
 * the loaders were server-rendered and gated on the cookie, so a full document
 * load was the only way to run them; now they are a sibling of this component
 * and a state change is enough.
 */
export function ConsentBanner({
  initialConsent,
  deferred = false,
  onChoice,
}: {
  initialConsent: ConsentValue | null;
  /** True while the first-visit language sheet is up — this bar sits at a
   * higher z-index and would cover its last option, so it waits its turn. */
  deferred?: boolean;
  /** Called after the choice is persisted, so the caller can mount (or keep
   * withholding) the trackers without a reload. */
  onChoice?: (value: ConsentValue) => void;
}) {
  const t = useTranslations("consent");
  const [choice, setChoice] = useState<ConsentValue | null>(initialConsent);
  const [waiting, setWaiting] = useState(deferred);

  useEffect(() => {
    if (!deferred) return;
    const onChosen = () => setWaiting(false);
    window.addEventListener(LANGUAGE_CHOSEN_EVENT, onChosen);
    return () => window.removeEventListener(LANGUAGE_CHOSEN_EVENT, onChosen);
  }, [deferred]);

  if (choice || waiting) return null;

  function persist(value: ConsentValue) {
    document.cookie = `${CONSENT_COOKIE}=${value}; Path=/; Max-Age=${CONSENT_MAX_AGE_SECONDS}; SameSite=Lax`;
    try {
      window.localStorage.setItem(CONSENT_COOKIE, value);
    } catch {
      // localStorage can throw in private mode / SSR; the cookie is the
      // source of truth so this is a nice-to-have only.
    }
    setChoice(value);
    onChoice?.(value);
  }

  return (
    <div
      // High z so it beats sticky headers and modals; fixed at bottom on
      // mobile, plate-shaped bar that respects safe-area on iOS. On phones it
      // sits above the fixed tab bar (h-14 + safe area) instead of on top of
      // it, which would bury the primary navigation until a choice is made.
      className="border-border bg-background/95 fixed inset-x-3 bottom-[calc(0.75rem+var(--tabbar))] z-[100] mx-auto max-w-2xl rounded-2xl border p-4 shadow-2xl backdrop-blur"
      role="dialog"
      aria-labelledby="consent-title"
      aria-describedby="consent-body"
    >
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="flex-1">
          <p
            id="consent-title"
            className="text-foreground text-sm font-semibold"
          >
            {t("title")}
          </p>
          <p
            id="consent-body"
            className="text-muted-foreground mt-1 text-xs leading-relaxed"
          >
            {t("body")}{" "}
            <Link
              href="/privacy"
              className="text-primary-ink font-medium hover:underline"
            >
              {t("learnMore")}
            </Link>
          </p>
        </div>
        <div className="flex shrink-0 flex-wrap justify-end gap-2">
          <button
            type="button"
            onClick={() => persist("denied")}
            className="text-muted-foreground border-border hover:bg-muted rounded-md border px-3 py-1.5 text-xs font-medium"
          >
            {t("reject")}
          </button>
          <button
            type="button"
            onClick={() => persist("granted")}
            className="bg-primary text-primary-foreground rounded-md px-3 py-1.5 text-xs font-semibold hover:opacity-90"
          >
            {t("accept")}
          </button>
        </div>
      </div>
    </div>
  );
}
