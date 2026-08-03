"use client";

import { Archive, Bookmark, Check, Share2 } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { useSavedJob } from "@/components/jobs/saved-jobs-provider";
import { toast } from "@/components/ui/toast";
import { toggleBookmark } from "@/lib/actions/bookmark";
import { toggleDismiss } from "@/lib/actions/dismiss";
import { cn } from "@/lib/utils";

const iconButton =
  "inline-flex size-9 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-foreground disabled:opacity-60";

/**
 * Compact share + save controls overlaid on a job card. Lives inside the card's
 * `<Link>`, so every handler cancels the click so the actions never navigate.
 * Bookmarking is optimistic and bounces a signed-out user to sign-in.
 */
export function JobCardActions({
  jobId,
  initialSaved = false,
  initialDismissed = false,
}: {
  jobId: string;
  initialSaved?: boolean;
  /** True on the archived-jobs list, where the button un-archives. */
  initialDismissed?: boolean;
}) {
  const t = useTranslations("jobs");
  const tb = useTranslations("bookmarks");
  const tc = useTranslations("common");
  const locale = useLocale();
  // Same split as BookmarkButton: `initialSaved` is the server's answer where
  // it has one, the provider supplies it on pages that must stay cacheable,
  // and a tap wins over both from then on.
  const hydrated = useSavedJob(jobId);
  const [saved, setSaved] = useState(initialSaved);
  const [touched, setTouched] = useState(false);
  const shown = touched || hydrated === null ? saved : initialSaved || hydrated;
  const [dismissed, setDismissed] = useState(initialDismissed);
  const [copied, setCopied] = useState(false);
  const [pending, startTransition] = useTransition();
  const [dismissPending, startDismissTransition] = useTransition();

  function cancel(event: React.MouseEvent) {
    event.preventDefault();
    event.stopPropagation();
  }

  function onBookmark(event: React.MouseEvent) {
    cancel(event);
    setTouched(true);
    setSaved(!shown);
    startTransition(async () => {
      const result = await toggleBookmark(jobId);
      if (result.signedOut) {
        setSaved(false);
        // Return them to the page they were on after sign-in (so the save is a
        // click away), rather than dropping them on /account.
        const next = encodeURIComponent(window.location.pathname);
        window.location.href = `/${locale}/sign-in?next=${next}`;
        return;
      }
      // `result.saved` is the server's truth either way, so a failed write
      // snaps the icon back instead of leaving a filled bookmark on a job
      // that was never saved. Say so too — silently reverting looks like a
      // misfired tap.
      setSaved(result.saved);
      if (result.error) toast({ title: tc("error"), variant: "error" });
    });
  }

  function onDismiss(event: React.MouseEvent) {
    cancel(event);
    setDismissed((d) => !d);
    startDismissTransition(async () => {
      const result = await toggleDismiss(jobId);
      if (result.signedOut) {
        setDismissed(false);
        const next = encodeURIComponent(window.location.pathname);
        window.location.href = `/${locale}/sign-in?next=${next}`;
        return;
      }
      setDismissed(result.dismissed);
      if (result.error) toast({ title: tc("error"), variant: "error" });
    });
  }

  async function onShare(event: React.MouseEvent) {
    cancel(event);
    const url = `${window.location.origin}/${locale}/jobs/${jobId}`;
    if (navigator.share) {
      try {
        await navigator.share({ url });
        return;
      } catch {
        // User dismissed the share sheet — fall through to copy.
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Clipboard unavailable (insecure context) — nothing else to do.
    }
  }

  return (
    <div className="flex shrink-0 items-center gap-0.5">
      <button
        type="button"
        onClick={onShare}
        aria-label={t("share")}
        className={iconButton}
      >
        {copied ? (
          <Check className="text-primary size-4" />
        ) : (
          <Share2 className="size-4" />
        )}
      </button>
      <button
        type="button"
        onClick={onBookmark}
        disabled={pending}
        aria-pressed={shown}
        aria-label={shown ? tb("saved") : tb("save")}
        className={cn(iconButton, shown && "text-primary hover:text-primary")}
      >
        {/* Keyed so the pop replays on each toggle, and only after a tap —
            see BookmarkButton for why the provider's fill must stay silent. */}
        <Bookmark
          key={touched ? `saved-${shown}` : "initial"}
          className={cn("size-4", touched && "tap-pop")}
          fill={shown ? "currentColor" : "none"}
        />
      </button>
      <button
        type="button"
        onClick={onDismiss}
        disabled={dismissPending}
        aria-pressed={dismissed}
        aria-label={dismissed ? t("dismissed") : t("dismiss")}
        title={dismissed ? t("dismissed") : t("dismiss")}
        className={cn(
          iconButton,
          dismissed && "text-primary hover:text-primary",
        )}
      >
        <Archive className="size-4" />
      </button>
    </div>
  );
}
