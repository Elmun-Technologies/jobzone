"use client";

import { Bookmark } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { useSavedJob } from "@/components/jobs/saved-jobs-provider";
import { toast } from "@/components/ui/toast";
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
  const tc = useTranslations("common");
  const locale = useLocale();
  // `initial` is the server's answer where it has one (the saved list, the
  // account pages). On a public page — which must stay cacheable and so cannot
  // read the session — it is always false, and the real state arrives from the
  // provider a beat later. `touched` keeps the provider from overwriting a tap
  // the visitor has already made.
  const hydrated = useSavedJob(jobId);
  const [saved, setSaved] = useState(initial);
  const [touched, setTouched] = useState(false);
  const shown = touched || hydrated === null ? saved : initial || hydrated;
  const [pending, startTransition] = useTransition();

  function onClick() {
    const optimistic = !shown;
    setTouched(true);
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
      // `result.saved` is the server's truth either way, so a failed write
      // snaps the icon back rather than leaving it filled on a job that was
      // never saved.
      setSaved(result.saved);
      if (result.error) {
        toast({ title: tc("error"), variant: "error" });
        return;
      }
      // Funnel event only on the add (not the remove) — the unsave is a
      // correction, not a retention signal we care to attribute.
      if (result.saved && !shown) {
        track("bookmark_added", { job_id: jobId });
      }
    });
  }

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={pending}
      aria-pressed={shown}
      aria-label={shown ? t("saved") : t("save")}
      className={cn(
        "border-border hover:bg-muted inline-flex h-10 items-center gap-2 rounded-full border px-4 text-sm font-semibold transition-colors disabled:opacity-60",
        shown ? "text-primary" : "text-foreground",
        className,
      )}
    >
      <Bookmark className="size-4" fill={shown ? "currentColor" : "none"} />
      {shown ? t("saved") : t("save")}
    </button>
  );
}
