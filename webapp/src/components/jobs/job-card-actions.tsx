"use client";

import { Bookmark, Check, Share2 } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useState, useTransition } from "react";

import { toggleBookmark } from "@/lib/actions/bookmark";
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
}: {
  jobId: string;
  initialSaved?: boolean;
}) {
  const t = useTranslations("jobs");
  const tb = useTranslations("bookmarks");
  const locale = useLocale();
  const [saved, setSaved] = useState(initialSaved);
  const [copied, setCopied] = useState(false);
  const [pending, startTransition] = useTransition();

  function cancel(event: React.MouseEvent) {
    event.preventDefault();
    event.stopPropagation();
  }

  function onBookmark(event: React.MouseEvent) {
    cancel(event);
    setSaved((s) => !s);
    startTransition(async () => {
      const result = await toggleBookmark(jobId);
      if (result.signedOut) {
        setSaved(false);
        window.location.href = `/${locale}/sign-in`;
        return;
      }
      setSaved(result.saved);
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
        aria-pressed={saved}
        aria-label={saved ? tb("saved") : tb("save")}
        className={cn(iconButton, saved && "text-primary hover:text-primary")}
      >
        <Bookmark className="size-4" fill={saved ? "currentColor" : "none"} />
      </button>
    </div>
  );
}
