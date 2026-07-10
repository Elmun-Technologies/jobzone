"use client";

import { useLocale, useTranslations } from "next-intl";
import { useTransition } from "react";

import { usePathname, useRouter } from "@/i18n/navigation";
import { routing, type Locale } from "@/i18n/routing";

const LOCALE_NAMES: Record<Locale, string> = {
  uz: "O'zbekcha",
  ru: "Русский",
  en: "English",
};

/** Switches locale while preserving the current path. */
export function LocaleSwitcher() {
  const locale = useLocale();
  const t = useTranslations("nav");
  const router = useRouter();
  const pathname = usePathname();
  const [isPending, startTransition] = useTransition();

  function onChange(event: React.ChangeEvent<HTMLSelectElement>) {
    const next = event.target.value as Locale;
    startTransition(() => {
      router.replace(pathname, { locale: next });
    });
  }

  return (
    <select
      value={locale}
      onChange={onChange}
      disabled={isPending}
      aria-label={t("language")}
      className="border-border bg-background text-foreground focus-visible:ring-ring h-9 rounded-full border px-3 text-sm font-medium focus-visible:ring-2 focus-visible:outline-none"
    >
      {routing.locales.map((l) => (
        <option key={l} value={l}>
          {LOCALE_NAMES[l]}
        </option>
      ))}
    </select>
  );
}
