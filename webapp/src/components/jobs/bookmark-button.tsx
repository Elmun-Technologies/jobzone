"use client";

import { Bookmark } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { toggleBookmark } from "@/lib/actions/bookmark";
import { track } from "@/lib/analytics/track";
import { cn } from "@/lib/utils";

/**
 * Save/unsave toggle. Optimistic; falls back to its previous state and sends a
 * signed-out user to sign-in. `initial` is computed on the server.
 */
export function BookmarkButton({
  jobId,
  initial,
  className,
}: {
  jobId: string;
  initial: boolean;
  className?: string;
}) {
  const t = useTranslations("bookmarks");
  const locale = useLocale();
  const [saved, setSaved] = useState(initial);
  const [pending, startTransition] = useTransition();

  function onClick() {
    const optimistic = !saved;
    setSaved(optimistic);
    startTransition(async () => {
      const result = await toggleBookmark(jobId);
      if (result.signedOut) {
        setSaved(initial);
        // Return them here after sign-in instead of dropping them on /account.
        const next = encodeURIComponent(window.location.pathname);
        window.location.href = `/${locale}/sign-in?next=${next}`;
        return;
      }
      setSaved(result.saved);
      // Funnel event only on the add (not the remove) — the unsave is a
      // correction, not a retention signal we care to attribute.
      if (result.saved && !initial) {
        track("bookmark_added", { job_id: jobId });
      }
    });
  }

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={pending}
      aria-pressed={saved}
      aria-label={saved ? t("saved") : t("save")}
      className={cn(
        "border-border hover:bg-muted inline-flex h-10 items-center gap-2 rounded-full border px-4 text-sm font-semibold transition-colors disabled:opacity-60",
        saved ? "text-primary" : "text-foreground",
        className,
      )}
    >
      <Bookmark className="size-4" fill={saved ? "currentColor" : "none"} />
      {saved ? t("saved") : t("save")}
    </button>
  );
}
