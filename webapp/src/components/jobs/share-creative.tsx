"use client";

import { Check, Copy, Download, Share2 } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState } from "react";

/**
 * Employer/seeker share block on a job page. The heart of it: one-tap access to
 * a ready-made, brand-designed vacancy image (Instagram Story / post) plus the
 * shareable link — so an employer can advertise a posting with no designer. The
 * images come from the server `/share/{format}` routes; the link itself carries
 * the same creative as its rich preview (og:image).
 */
export function ShareCreative({
  basePath,
  shareUrl,
  title,
}: {
  /** Locale-scoped job path, e.g. `/uz/jobs/abc`. Download routes hang off it. */
  basePath: string;
  /** Absolute URL to share (rich preview attached automatically). */
  shareUrl: string;
  /** Job title, used as the share sheet's text. */
  title: string;
}) {
  const t = useTranslations("jobs");
  const [copied, setCopied] = useState(false);

  async function onShare() {
    if (navigator.share) {
      try {
        await navigator.share({ title, url: shareUrl });
        return;
      } catch {
        // dismissed — fall through to copy
      }
    }
    await copy();
  }

  async function copy() {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      // clipboard blocked — no-op
    }
  }

  const download =
    "border-border text-foreground hover:border-primary/40 hover:bg-muted flex items-center justify-center gap-2 rounded-full border py-2.5 text-sm font-semibold transition-colors";

  return (
    <div className="border-border bg-card mt-4 rounded-xl border p-5">
      <p className="text-foreground text-sm font-semibold">
        {t("shareCreativeTitle")}
      </p>
      <p className="text-muted-foreground mt-1 text-xs">
        {t("shareCreativeHint")}
      </p>

      {/* Live preview of the generated creative (the link-preview format). */}
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={`${basePath}/share/og`}
        alt={title}
        width={1200}
        height={630}
        loading="lazy"
        className="border-border mt-3 aspect-[1200/630] w-full rounded-lg border object-cover"
      />

      <button
        type="button"
        onClick={onShare}
        className="bg-primary text-primary-foreground hover:bg-primary/90 mt-3 flex w-full items-center justify-center gap-2 rounded-full py-3 text-sm font-semibold transition-colors"
      >
        <Share2 className="size-4" />
        {t("share")}
      </button>

      <div className="mt-2 grid grid-cols-2 gap-2">
        <a href={`${basePath}/share/story`} download className={download}>
          <Download className="size-4" />
          {t("shareStory")}
        </a>
        <a href={`${basePath}/share/post`} download className={download}>
          <Download className="size-4" />
          {t("sharePost")}
        </a>
      </div>

      <button
        type="button"
        onClick={copy}
        className="text-muted-foreground hover:text-foreground mt-2 flex w-full items-center justify-center gap-2 py-1.5 text-xs font-medium transition-colors"
      >
        {copied ? (
          <>
            <Check className="size-3.5" />
            {t("shareCopied")}
          </>
        ) : (
          <>
            <Copy className="size-3.5" />
            {t("shareCopy")}
          </>
        )}
      </button>
    </div>
  );
}
