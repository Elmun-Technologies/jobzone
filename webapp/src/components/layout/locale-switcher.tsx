"use client";

import { useLocale, useTranslations } from "next-intl";
import { useTransition } from "react";

import { usePathname, useRouter } from "@/i18n/navigation";
import { routing, type Locale } from "@/i18n/routing";
import { setPreferredLocale } from "@/lib/actions/profile";
import { rememberLocaleChoice } from "@/lib/locale-choice";
import { cn } from "@/lib/utils";

/** Full names for the drawer, two-letter codes for the header pill. */
const LOCALE_NAMES: Record<Locale, string> = {
  uz: "O'zbekcha",
  ru: "Русский",
  en: "English",
};
const LOCALE_SHORT: Record<Locale, string> = {
  uz: "UZ",
  ru: "RU",
  en: "EN",
};

const segment =
  "rounded-full px-2.5 py-1 text-sm font-medium transition-colors disabled:opacity-60";
const active = "bg-background text-foreground shadow-sm";
const inactive = "text-muted-foreground hover:text-foreground";

/**
 * Switches locale while preserving the current path.
 *
 * A segmented pill rather than a `<select>`: the native control rendered an
 * OS dropdown that ignored every brand token (a full-screen wheel on mobile),
 * and its width was set by the longest language name, which is what made the
 * header look lopsided. This mirrors `RoleToggle` — same pill, same thumb —
 * so the two controls in the header read as one system.
 *
 * `compact` (the default) shows UZ/RU/EN; the mobile drawer has room for the
 * full names.
 */
export function LocaleSwitcher({ compact = true }: { compact?: boolean }) {
  const locale = useLocale();
  const t = useTranslations("nav");
  const router = useRouter();
  const pathname = usePathname();
  const [isPending, startTransition] = useTransition();

  function switchTo(next: Locale) {
    if (next === locale) return;
    // An explicit switch here is the same decision the first-visit sheet asks
    // for — record it so the sheet never interrupts this visitor again.
    rememberLocaleChoice(next);
    // Fire-and-forget: the backend composes push/Telegram server-side, where
    // the URL prefix and the next-intl cookie are invisible, so the profile is
    // the only place it can learn which language to write in. Not awaited —
    // the switch must feel instant and must not fail if this does.
    void setPreferredLocale(next);
    // `usePathname` is next-intl's useBasePathname, which wraps Next's
    // usePathname — path only, no query. Passing it alone sent a seeker who
    // had searched /jobs?q=haydovchi&city=Toshkent to a bare /ru/jobs, i.e.
    // changing language silently cleared their search. Read the live query at
    // click time (rather than useSearchParams, which would drag a Suspense
    // requirement into the header on every page) and carry it across.
    const search = typeof window === "undefined" ? "" : window.location.search;
    startTransition(() => {
      router.replace(`${pathname}${search}`, { locale: next });
    });
  }

  return (
    <div
      role="group"
      aria-label={t("language")}
      className="bg-muted inline-flex shrink-0 items-center rounded-full p-1"
    >
      {routing.locales.map((l) => {
        const isActive = l === locale;
        return (
          <button
            key={l}
            type="button"
            onClick={() => switchTo(l)}
            disabled={isPending}
            aria-current={isActive ? "true" : undefined}
            className={cn(segment, isActive ? active : inactive)}
          >
            {compact ? LOCALE_SHORT[l] : LOCALE_NAMES[l]}
          </button>
        );
      })}
    </div>
  );
}
