"use client";

import { useLocale, useTranslations } from "next-intl";
import { useCallback, useEffect, useRef, useState } from "react";

import { QuickApplyButton } from "@/components/jobs/quick-apply-button";
import type { Job } from "@/lib/data/types";
import {
  formatDistanceMeters,
  salaryPill,
  schedulePatternLabel,
} from "@/lib/format";

import { mapTier } from "./tier";

/** Average rating + review count per company id (from company_reviews). */
export type PinRating = { avg: number; count: number };

/**
 * The pin's hover preview — the mockup's card: company logo, title, live
 * rating, volt salary chip, meta line and a one-tap apply CTA. Rendered by
 * the React wrapper around the map (not by the map engine), so it looks and
 * behaves identically on Yandex and Leaflet, and the CTA is the real
 * QuickApplyButton (server action), not injected HTML.
 */
export function JobPinCard({
  job,
  rating,
  distance,
}: {
  job: Job;
  rating?: PinRating;
  /** Metres from the user's location; omitted when location is unknown. */
  distance?: number | null;
}) {
  const locale = useLocale();
  const t = useTranslations("apply");
  const salary = salaryPill(job);
  const tier = mapTier(job.boostKind);
  const meta = [
    job.categoryName,
    distance != null ? formatDistanceMeters(distance) : null,
    schedulePatternLabel(job.schedulePattern),
  ]
    .filter(Boolean)
    .join(" · ");

  return (
    <div
      className={`bg-background w-[290px] rounded-2xl border p-4 shadow-2xl ${
        // A paid listing keeps its volt accent on the card too.
        tier ? "border-primary ring-primary/25 ring-2" : "border-border"
      }`}
    >
      <div className="flex items-start gap-3">
        {job.companyLogoUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={job.companyLogoUrl}
            alt={job.companyName}
            width={40}
            height={40}
            // A dead logo URL hides itself instead of showing a broken image.
            onError={(e) => {
              e.currentTarget.style.display = "none";
            }}
            className={`size-10 shrink-0 rounded-lg object-cover ${
              tier
                ? "ring-primary shadow-[0_0_10px_rgba(199,251,0,0.5)] ring-2"
                : ""
            }`}
          />
        ) : (
          <div className="bg-primary text-primary-foreground flex size-10 shrink-0 items-center justify-center rounded-lg font-bold">
            {job.companyName.charAt(0).toUpperCase()}
          </div>
        )}
        <div className="min-w-0 flex-1">
          <a
            href={`/${locale}/jobs/${job.id}`}
            className="text-foreground block truncate text-base leading-tight font-bold hover:underline"
          >
            {job.title}
          </a>
          <div className="text-muted-foreground truncate text-sm">
            {job.companyName}
            {rating && rating.count > 0 ? (
              <span className="text-foreground font-semibold">
                {" "}
                · ⭐ {rating.avg.toFixed(1)}{" "}
                <span className="text-muted-foreground font-normal">
                  ({rating.count})
                </span>
              </span>
            ) : null}
          </div>
        </div>
        {salary ? (
          <span className="bg-primary text-primary-foreground shrink-0 rounded-full px-2.5 py-1 font-mono text-xs font-bold">
            {salary}
          </span>
        ) : null}
      </div>

      {meta ? (
        <div className="text-muted-foreground mt-2 truncate font-mono text-xs">
          {meta}
        </div>
      ) : null}

      <QuickApplyButton
        jobId={job.id}
        needsForm={job.screeningQuestions.some((q) => q.required)}
        className="mt-3 w-full px-4 py-2 text-sm"
      />
      <div className="text-muted-foreground mt-1.5 text-center text-xs">
        {t("quickApplyHint")}
      </div>
    </div>
  );
}

export type PinHover = {
  jobId: string;
  /** Card anchor, in the map wrapper's coordinate space. */
  x: number;
  y: number;
  /** True when there's no room above the pin — the card opens below it. */
  flip: boolean;
};

/**
 * Engine-agnostic hover/click wiring for the salary pins. Both map engines
 * render pins as plain DOM carrying `data-job-id` (see pin-markup.ts), so a
 * single set of delegated listeners on the map wrapper covers Yandex and
 * Leaflet alike: hovering a pin (or the card itself) shows/keeps the preview
 * card, leaving both closes it after a grace period, clicking a pin opens
 * the job page.
 */
export function usePinHover(onPinClick: (jobId: string) => void) {
  const wrapRef = useRef<HTMLDivElement | null>(null);
  const [hover, setHover] = useState<PinHover | null>(null);
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const cancelClose = useCallback(() => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
  }, []);
  const scheduleClose = useCallback(() => {
    cancelClose();
    closeTimer.current = setTimeout(() => setHover(null), 140);
  }, [cancelClose]);
  useEffect(() => cancelClose, [cancelClose]);

  const onMouseOver = useCallback(
    (e: React.MouseEvent) => {
      const target = e.target as HTMLElement;
      if (target.closest("[data-pin-card]")) {
        cancelClose();
        return;
      }
      const pin = target.closest<HTMLElement>("[data-job-id]");
      const wrap = wrapRef.current;
      if (!pin?.dataset.jobId || !wrap) {
        // The pointer surfaced somewhere that's neither pin nor card — close
        // even if the pin's own mouseout got swallowed (e.g. the map engine
        // replaced the pin's DOM node under the cursor).
        scheduleClose();
        return;
      }
      cancelClose();
      const r = pin.getBoundingClientRect();
      const w = wrap.getBoundingClientRect();
      // Half the card width keeps it inside the map; flip below when the pin
      // sits too close to the top edge for the card to fit above it.
      const half = 150;
      const flip = r.top - w.top < 270;
      setHover({
        jobId: pin.dataset.jobId,
        x: Math.min(
          Math.max(r.left + r.width / 2 - w.left, half),
          Math.max(w.width - half, half),
        ),
        y: flip ? r.bottom - w.top + 10 : r.top - w.top - 10,
        flip,
      });
    },
    [cancelClose, scheduleClose],
  );

  const onMouseOut = useCallback(
    (e: React.MouseEvent) => {
      const target = e.target as HTMLElement;
      if (
        target.closest("[data-job-id]") ||
        target.closest("[data-pin-card]")
      ) {
        scheduleClose();
      }
    },
    [scheduleClose],
  );

  const onClick = useCallback(
    (e: React.MouseEvent) => {
      const target = e.target as HTMLElement;
      if (target.closest("[data-pin-card]")) return; // card handles its own links
      const pin = target.closest<HTMLElement>("[data-job-id]");
      if (pin?.dataset.jobId) onPinClick(pin.dataset.jobId);
    },
    [onPinClick],
  );

  return {
    wrapRef,
    hover,
    // onMouseLeave backstops the boundary events: it fires when the pointer
    // exits the wrapper itself, even if a map engine replaced the hovered
    // pin's DOM node and its mouseout was never dispatched.
    handlers: { onMouseOver, onMouseOut, onClick, onMouseLeave: scheduleClose },
  };
}

/** Positions the hover card at the pin, above or below per `hover.flip`. */
export function PinCardOverlay({
  hover,
  job,
  rating,
  distance,
}: {
  hover: PinHover;
  job: Job;
  rating?: PinRating;
  distance?: number | null;
}) {
  return (
    <div
      data-pin-card
      className="absolute z-[1100]"
      style={{
        left: hover.x,
        top: hover.y,
        transform: hover.flip ? "translate(-50%,0)" : "translate(-50%,-100%)",
      }}
    >
      <JobPinCard job={job} rating={rating} distance={distance} />
    </div>
  );
}
