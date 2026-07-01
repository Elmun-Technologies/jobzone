"use client";

import { Trash2 } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useTransition } from "react";

import { deleteSavedSearch } from "@/lib/actions/saved-search";

export function DeleteSavedSearchButton({ id }: { id: string }) {
  const t = useTranslations("savedSearches");
  const locale = useLocale();
  const [pending, start] = useTransition();

  return (
    <button
      type="button"
      aria-label={t("delete")}
      disabled={pending}
      onClick={() => start(() => deleteSavedSearch(id, locale))}
      className="text-muted-foreground hover:text-destructive shrink-0 rounded-lg p-2 transition-colors disabled:opacity-50"
    >
      <Trash2 className="size-4" />
    </button>
  );
}
