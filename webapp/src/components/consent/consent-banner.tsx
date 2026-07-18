"use client";

import { useTranslations } from "next-intl";
import { useState } from "react";

import { Link } from "@/i18n/navigation";
import {
  CONSENT_COOKIE,
  CONSENT_MAX_AGE_SECONDS,
  type ConsentValue,
} from "@/lib/consent";

/**
 * Cookie banner. Server layout reads the cookie and forwards it here as
 * `initialConsent`; if that's null (visitor hasn't chosen yet) we mount
 * the sticky bar. When the visitor clicks accept/reject we persist to
 * the cookie AND to localStorage so the mobile app's WebView (if we ever
 * add one) can inherit the choice, then reload — analytics loaders are
 * server-rendered `<Script>`s gated on the cookie, and a full refresh is
 * the cheapest way to actually run them once the visitor opts in.
 */
export function ConsentBanner({
  initialConsent,
}: {
  initialConsent: ConsentValue | null;
}) {
  const t = useTranslations("consent");
  const [choice, setChoice] = useState<ConsentValue | null>(initialConsent);

  if (choice) return null;

  function persist(value: ConsentValue) {
    document.cookie = `${CONSENT_COOKIE}=${value}; Path=/; Max-Age=${CONSENT_MAX_AGE_SECONDS}; SameSite=Lax`;
    try {
      window.localStorage.setItem(CONSENT_COOKIE, value);
    } catch {
      // localStorage can throw in private mode / SSR; the cookie is the
      // source of truth so this is a nice-to-have only.
    }
    setChoice(value);
    // Reload so the server layout re-reads the cookie and this time mounts
    // the analytics <Script> tags.
    window.location.reload();
  }

  return (
    <div
      // High z so it beats sticky headers and modals; fixed at bottom on
      // mobile, plate-shaped bar that respects safe-area on iOS.
      className="fixed inset-x-3 bottom-3 z-[100] mx-auto max-w-2xl rounded-2xl border border-border bg-background/95 p-4 shadow-2xl backdrop-blur"
      role="dialog"
      aria-labelledby="consent-title"
      aria-describedby="consent-body"
    >
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="flex-1">
          <p id="consent-title" className="text-foreground text-sm font-semibold">
            {t("title")}
          </p>
          <p
            id="consent-body"
            className="text-muted-foreground mt-1 text-xs leading-relaxed"
          >
            {t("body")}{" "}
            <Link
              href="/privacy"
              className="text-primary font-medium hover:underline"
            >
              {t("learnMore")}
            </Link>
          </p>
        </div>
        <div className="flex shrink-0 flex-wrap justify-end gap-2">
          <button
            type="button"
            onClick={() => persist("denied")}
            className="text-muted-foreground rounded-md border border-border px-3 py-1.5 text-xs font-medium hover:bg-muted"
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
