"use client";

import { BadgeCheck, Clock, MapPin } from "lucide-react";
import Image from "next/image";
import { useTranslations } from "next-intl";

import { Link } from "@/i18n/navigation";
import type { Job } from "@/lib/data/types";
import { locationText, postedInfo, salaryText } from "@/lib/format";
import { useNow } from "@/lib/use-now";

import { JobCardActions } from "./job-card-actions";
import { QuickApplyButton } from "./quick-apply-button";

function Chip({ children }: { children: React.ReactNode }) {
  return (
    <span className="bg-muted text-muted-foreground rounded-full px-2.5 py-1 text-xs font-medium">
      {children}
    </span>
  );
}

export function JobCard({ job, saved = false }: { job: Job; saved?: boolean }) {
  const t = useTranslations("jobs");
  const nowMs = useNow();
  const salary = salaryText(job);
  const loc = locationText(job);
  // Listing-tier visuals from boostKind (legacy boosts map to the nearest tier).
  const glow =
    job.boostKind === "brand" ||
    job.boostKind === "premium" ||
    job.boostKind === "featured";
  const standout = job.boostKind === "premium" || job.boostKind === "top";

  const typeLabel =
    job.jobType && t.has(`type.${job.jobType}`)
      ? t(`type.${job.jobType}`)
      : job.jobType;
  const modelLabel =
    job.workingModel && t.has(`model.${job.workingModel}`)
      ? t(`model.${job.workingModel}`)
      : job.workingModel;

  const info = nowMs == null ? null : postedInfo(job.postedAt, nowMs);
  let timeText = "";
  if (info) {
    if (info.dayOffset === 0) timeText = `${t("postedToday")} ${info.clock}`;
    else if (info.dayOffset === 1)
      timeText = `${t("postedYesterday")} ${info.clock}`;
    else timeText = t("daysAgo", { days: info.dayOffset });
  }
  // Same gate the job-detail page's QuickApplyButton already uses.
  const needsForm = job.screeningQuestions.some((q) => q.required);

  return (
    <Link
      href={`/jobs/${job.id}`}
      className={`hover:bg-muted/30 block rounded-xl border p-4 transition-colors ${
        standout
          ? "border-primary bg-primary/[0.04] ring-primary/20 shadow-[0_6px_28px_-8px_rgba(199,251,0,0.55)] ring-2"
          : "border-border bg-card hover:border-primary/40"
      }`}
    >
      <div className="flex gap-3">
        {/* Company logo or brand-initial fallback. The seed_prod placeholder
            path is gone; every logo now either comes from Supabase Storage
            (real employer upload) or is null → we render the volt initial. */}
        {job.companyLogoUrl ? (
          <Image
            src={job.companyLogoUrl}
            alt={job.companyName}
            width={48}
            height={48}
            // Below-the-fold on a long list; browser handles native lazy.
            loading="lazy"
            // Fixed pixel size — one srcset entry is enough; Next still emits
            // width/height so layout doesn't shift on load.
            sizes="48px"
            className={`size-12 shrink-0 rounded-lg object-cover ${
              glow
                ? "ring-primary shadow-[0_0_12px_rgba(199,251,0,0.55)] ring-2"
                : ""
            }`}
          />
        ) : (
          <div
            className={`bg-primary text-primary-foreground flex size-12 shrink-0 items-center justify-center rounded-lg font-bold ${
              glow ? "shadow-[0_0_12px_rgba(199,251,0,0.55)]" : ""
            }`}
          >
            {job.companyName.charAt(0).toUpperCase()}
          </div>
        )}

        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <div className="flex items-start gap-2">
                {/* Wrap to two lines instead of truncating — on a phone the
                    single-line ellipsis left 4-6 characters of the title. */}
                <h3 className="text-foreground line-clamp-2 min-w-0 font-semibold">
                  {job.title}
                </h3>
                {standout ? (
                  <span className="bg-primary text-primary-foreground shrink-0 rounded-full px-2 py-0.5 text-xs font-bold">
                    {job.boostKind === "premium" ? t("tierPremium") : "TOP"}
                  </span>
                ) : glow ? (
                  <span className="border-primary text-foreground shrink-0 rounded-full border px-2 py-0.5 text-xs font-bold">
                    {t("tierBrand")}
                  </span>
                ) : job.boostActive ? (
                  <span className="bg-primary text-primary-foreground shrink-0 rounded-full px-2 py-0.5 text-xs font-bold">
                    TOP
                  </span>
                ) : null}
              </div>
              <div className="text-muted-foreground mt-0.5 flex items-center gap-1 text-sm">
                <span className="truncate">{job.companyName}</span>
                {job.companyVerified ? (
                  <BadgeCheck className="text-primary size-4 shrink-0" />
                ) : null}
              </div>
            </div>
            <JobCardActions jobId={job.id} initialSaved={saved} />
          </div>

          {loc ? (
            <div className="text-muted-foreground mt-1 flex items-center gap-1 text-sm">
              <MapPin className="size-3.5 shrink-0" />
              <span className="truncate">{loc}</span>
            </div>
          ) : null}

          <div className="mt-3 flex flex-wrap items-center gap-2">
            <span
              className={`text-foreground text-sm font-semibold ${salary ? "font-mono" : ""}`}
            >
              {salary ?? t("negotiable")}
            </span>
            {typeLabel ? <Chip>{typeLabel}</Chip> : null}
            {modelLabel ? <Chip>{modelLabel}</Chip> : null}
          </div>

          {info ? (
            <div
              className="mt-3 flex items-center gap-2 text-xs"
              suppressHydrationWarning
            >
              {info.fresh ? (
                <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 font-semibold text-green-700 dark:bg-green-500/15 dark:text-green-400">
                  <span className="size-1.5 rounded-full bg-current" />
                  {t("justPosted")}
                </span>
              ) : null}
              {timeText ? (
                <span className="text-muted-foreground inline-flex items-center gap-1">
                  <Clock className="size-3.5" />
                  {timeText}
                </span>
              ) : null}
            </div>
          ) : null}

          {/* The card is one big <Link>; stop the tap from also navigating. */}
          <div
            className="mt-3"
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
            }}
          >
            <QuickApplyButton
              jobId={job.id}
              needsForm={needsForm}
              className="w-full justify-center"
            />
          </div>
        </div>
      </div>
    </Link>
  );
}
