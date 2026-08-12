"use client";

import { Check, X } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { usePathname } from "@/i18n/navigation";
import { routing, type Locale } from "@/i18n/routing";
import { setPreferredLocale } from "@/lib/actions/profile";
import { captureDrafts } from "@/lib/draft-stash";
import { goToLocale } from "@/lib/locale-nav";
import {
  LANGUAGE_CHOSEN_EVENT,
  rememberLocaleChoice,
} from "@/lib/locale-choice";
import { cn } from "@/lib/utils";

const NAMES: Record<Locale, string> = {
  uz: "O'zbekcha",
  ru: "Русский",
  en: "English",
};

// Regional-indicator pairs. Phones — the entire audience for this sheet —
// render them as flags; the desktop browsers that don't fall back to the
// country letters, which still reads correctly next to the language name.
const FLAGS: Record<Locale, string> = {
  uz: "🇺🇿",
  ru: "🇷🇺",
  en: "🇬🇧",
};

/**
 * First-visit language chooser, shown once as a bottom sheet.
 *
 * Uzbekistan is a genuinely three-language market and every inbound link lands
 * on the default locale, so a share of first-time visitors arrive on a page in
 * a language they don't read and have to discover a UZ/RU/EN pill in the
 * header (which, below `xl`, is inside the drawer) to fix it. Asking once, up
 * front, is what the local apps do — and it is a 3-tap fix instead of a
 * bounce. The choice is remembered in a cookie, so this never appears twice.
 */
export function LanguageSheet() {
  const active = useLocale() as Locale;
  const t = useTranslations("localeSwitcher");
  const pathname = usePathname();
  const [open, setOpen] = useState(true);
  const [pending, start] = useTransition();

  function choose(next: Locale) {
    rememberLocaleChoice(next);
    close();
    if (next === active) return;
    // Fire-and-forget, exactly as the header switcher does: the server
    // composes push/Telegram copy from the profile, which is the only place
    // it can learn the language — but the navigation must not wait on it.
    void setPreferredLocale(next);
    // Park any draft on screen: this navigation rebuilds everything under
    // `[locale]`, so an unparked form comes back empty, and the sheet can
    // appear over a half-filled application.
    captureDrafts();
    // Full document load, like the header switcher — the query and hash ride
    // along, and the theme survives because the pre-paint script runs again
    // (see lib/locale-nav.ts).
    start(() => goToLocale(next, pathname));
  }

  function dismiss() {
    // Closing without choosing still counts as a decision — "the language I'm
    // looking at is fine". Nagging on every page view would be worse than not
    // asking at all.
    rememberLocaleChoice(active);
    close();
  }

  function close() {
    setOpen(false);
    // Releases the cookie bar, which holds itself back while this is up: two
    // stacked dialogs on a first visit is one too many, and the consent text
    // is easier to answer in a language the visitor has just confirmed.
    window.dispatchEvent(new Event(LANGUAGE_CHOSEN_EVENT));
  }

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[90] flex items-end justify-center sm:items-center">
      <button
        type="button"
        aria-label={t("close")}
        onClick={dismiss}
        className="bg-foreground/40 absolute inset-0 backdrop-blur-sm"
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="lang-sheet-title"
        className="border-border bg-background relative w-full max-w-md rounded-t-3xl border p-6 pb-[calc(1.5rem+env(safe-area-inset-bottom))] shadow-2xl sm:rounded-3xl sm:pb-6"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2
              id="lang-sheet-title"
              className="text-foreground text-xl font-bold"
            >
              {t("sheetTitle")}
            </h2>
            <p className="text-muted-foreground mt-1 text-sm">
              {t("sheetBody")}
            </p>
          </div>
          <button
            type="button"
            onClick={dismiss}
            aria-label={t("close")}
            className="text-muted-foreground hover:bg-muted -mt-1 rounded-full p-1.5"
          >
            <X className="size-5" />
          </button>
        </div>

        <ul className="mt-5 space-y-2">
          {routing.locales.map((l) => {
            const on = l === active;
            return (
              <li key={l}>
                <button
                  type="button"
                  disabled={pending}
                  onClick={() => choose(l)}
                  aria-current={on ? "true" : undefined}
                  className={cn(
                    "flex w-full items-center gap-3 rounded-2xl border px-4 py-3.5 text-left transition-colors disabled:opacity-60",
                    on
                      ? "border-primary bg-accent"
                      : "border-border bg-card hover:border-primary/40",
                  )}
                >
                  <span aria-hidden className="text-xl leading-none">
                    {FLAGS[l]}
                  </span>
                  <span
                    className={cn(
                      "flex-1 font-semibold",
                      on ? "text-accent-foreground" : "text-foreground",
                    )}
                  >
                    {NAMES[l]}
                  </span>
                  {on ? <Check className="text-foreground size-5" /> : null}
                </button>
              </li>
            );
          })}
        </ul>
      </div>
    </div>
  );
}
