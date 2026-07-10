"use client";

import { Check, Copy, Download, Share2 } from "lucide-react";
import { useTranslations } from "next-intl";
import { useState } from "react";

/**
 * Employer promote surface: the three ready-made share creatives for a vacancy
 * (Instagram Story / post / link preview), each downloadable, plus a native
 * share, copy-link, and a short "how to post" guide. The point is that an
 * employer advertises a posting on Instagram with no designer — tap, download,
 * post, done. Images come from the server `/share/{format}` routes.
 */
const FORMATS = [
  { key: "story", labelKey: "shareStory", ratio: "1080 / 1920" },
  { key: "post", labelKey: "sharePost", ratio: "1080 / 1080" },
  { key: "og", labelKey: "shareLinkPreview", ratio: "1200 / 630" },
] as const;

export function PromoteCreative({
  basePath,
  shareUrl,
  title,
}: {
  basePath: string;
  shareUrl: string;
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
        // dismissed
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
      // clipboard blocked
    }
  }

  return (
    <div>
      <div className="grid gap-4 sm:grid-cols-3">
        {FORMATS.map((f) => (
          <div
            key={f.key}
            className="border-border bg-card flex flex-col gap-3 rounded-xl border p-3"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={`${basePath}/share/${f.key}`}
              alt={`${title} — ${t(f.labelKey)}`}
              loading="lazy"
              style={{ aspectRatio: f.ratio }}
              className="border-border w-full rounded-lg border object-cover"
            />
            <a
              href={`${basePath}/share/${f.key}`}
              download
              className="border-border text-foreground hover:border-primary/40 hover:bg-muted flex items-center justify-center gap-2 rounded-full border py-2 text-sm font-semibold transition-colors"
            >
              <Download className="size-4" />
              {t(f.labelKey)}
            </a>
          </div>
        ))}
      </div>

      <div className="mt-4 flex flex-col gap-2 sm:flex-row">
        <button
          type="button"
          onClick={onShare}
          className="bg-primary text-primary-foreground hover:bg-primary/90 flex flex-1 items-center justify-center gap-2 rounded-full py-3 text-sm font-semibold transition-colors"
        >
          <Share2 className="size-4" />
          {t("share")}
        </button>
        <button
          type="button"
          onClick={copy}
          className="border-border text-foreground hover:bg-muted flex flex-1 items-center justify-center gap-2 rounded-full border py-3 text-sm font-semibold transition-colors"
        >
          {copied ? (
            <>
              <Check className="size-4" />
              {t("shareCopied")}
            </>
          ) : (
            <>
              <Copy className="size-4" />
              {t("shareCopy")}
            </>
          )}
        </button>
      </div>

      <ol className="text-muted-foreground mt-6 space-y-2 text-sm">
        <li className="flex gap-3">
          <Step n={1} />
          {t("igStep1")}
        </li>
        <li className="flex gap-3">
          <Step n={2} />
          {t("igStep2")}
        </li>
        <li className="flex gap-3">
          <Step n={3} />
          {t("igStep3")}
        </li>
      </ol>
    </div>
  );
}

function Step({ n }: { n: number }) {
  return (
    <span className="bg-accent text-accent-foreground flex size-6 shrink-0 items-center justify-center rounded-full text-xs font-bold">
      {n}
    </span>
  );
}
