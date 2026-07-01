"use client";

import { BookmarkPlus, Check } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useState, useTransition } from "react";

import { saveSearch } from "@/lib/actions/saved-search";

/**
 * "Save this search" affordance on the jobs page. Web-native (no bottom sheet):
 * it captures the current URL filters and saves them for the seeker. Auth-last
 * — a guest is sent to sign in and back; the search lives in the URL, so it's
 * preserved across the round-trip with no stashing.
 */
export function SaveSearchButton() {
  const t = useTranslations("savedSearches");
  const locale = useLocale();
  const params = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const [saved, setSaved] = useState(false);
  const [pending, start] = useTransition();

  const q = params.get("q") ?? "";
  const city = params.get("city") ?? "";
  const category = params.get("category") ?? "";
  // Only worth offering when there's actually a criterion to save.
  if (!q && !city && !category) return null;

  function onSave() {
    const name = q || category || city;
    start(async () => {
      const res = await saveSearch({
        locale,
        name,
        keywords: q || category,
        city,
      });
      if (res.signedOut) {
        const next = `${pathname}?${params.toString()}`;
        router.push(`/${locale}/sign-in?next=${encodeURIComponent(next)}`);
      } else if (res.ok) {
        setSaved(true);
      }
    });
  }

  return (
    <button
      type="button"
      onClick={onSave}
      disabled={pending || saved}
      className="border-border text-foreground hover:border-primary/40 flex h-10 shrink-0 items-center gap-1.5 rounded-full border px-3 text-sm font-medium transition-colors disabled:opacity-70"
    >
      {saved ? (
        <Check className="size-4 text-emerald-600" />
      ) : (
        <BookmarkPlus className="size-4" />
      )}
      {saved ? t("saved") : t("save")}
    </button>
  );
}
