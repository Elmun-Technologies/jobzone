"use client";

import { Minus, Navigation, Plus } from "lucide-react";
import { useState } from "react";

import { Link } from "@/i18n/navigation";
import type { Job } from "@/lib/data/types";
import { salaryPill, schedulePatternLabel } from "@/lib/format";
import { cn } from "@/lib/utils";

import { LANDING_MAP_PIN_COUNT } from "./landing-map-shared";

// Fixed decorative viewport. Pins snap onto SLOTS so the composition always
// reads well regardless of which N jobs happen to have salary. The real,
// pannable map lives on /explore — this is the landing hero showcase.
const VIEW_W = 800;
const VIEW_H = 480;

const SLOTS: { x: number; y: number }[] = [
  { x: 210, y: 130 },
  { x: 560, y: 118 },
  { x: 685, y: 210 },
  { x: 605, y: 330 },
  { x: 310, y: 360 },
  { x: 170, y: 250 },
  { x: 460, y: 405 },
  { x: 720, y: 400 },
];
// Fail loudly if SLOTS and the shared cap drift apart — the RSC caller trims
// on the shared value; SLOTS[i] would blow up if there were more jobs.
if (SLOTS.length !== LANDING_MAP_PIN_COUNT) {
  throw new Error("landing-map SLOTS and LANDING_MAP_PIN_COUNT are out of sync");
}

type Labels = {
  chipNearMe: string;
  chipSalary: string;
  chipSchedule: string;
  /** Pre-formatted "N ta vakansiya" string (server components can't pass
   * a function into a Client Component, so the caller resolves the ICU). */
  results: string;
  nearMeCta: string;
  youAreHere: string;
  pinHint: string;
  cityLabel: string;
  negotiable: string;
};

export function LandingMap({
  jobs,
  labels,
}: {
  /** Already trimmed via pickLandingMapJobs on the server. */
  jobs: Job[];
  labels: Labels;
}) {
  const pinned = jobs;
  const [active, setActive] = useState<string | null>(null);

  return (
    <div className="border-border relative overflow-hidden rounded-2xl border">
      <div
        className="relative w-full"
        // Aspect matches the viewBox so the SVG scales without letterboxing.
        style={{ aspectRatio: `${VIEW_W} / ${VIEW_H}` }}
      >
        <svg
          viewBox={`0 0 ${VIEW_W} ${VIEW_H}`}
          preserveAspectRatio="xMidYMid slice"
          className="absolute inset-0 h-full w-full"
          aria-hidden
        >
          <StylizedMap />
        </svg>

        {/* You-are-here anchor + dashed radius rings. Center of the viewport. */}
        <YouAreHere label={labels.youAreHere} />

        {/* Salary pins on top of the map. */}
        {pinned.map((job, i) => {
          const slot = SLOTS[i];
          const left = (slot.x / VIEW_W) * 100;
          const top = (slot.y / VIEW_H) * 100;
          const pill = salaryPill(job) ?? labels.negotiable;
          return (
            <SalaryPin
              key={job.id}
              job={job}
              pill={pill}
              left={left}
              top={top}
              open={active === job.id}
              onOpen={() =>
                setActive((cur) => (cur === job.id ? null : job.id))
              }
            />
          );
        })}

        {/* Top chips — decorative but functional: each opens /explore filtered. */}
        <div className="pointer-events-none absolute inset-x-3 top-3 z-20 flex flex-wrap items-start gap-2 sm:inset-x-4 sm:top-4">
          <ChipLink href="/explore#near">{labels.chipNearMe}</ChipLink>
          <ChipLink href="/explore?minSalary=4000000">
            {labels.chipSalary}
          </ChipLink>
          <ChipLink href="/explore?schedule=2_2">
            {labels.chipSchedule}
          </ChipLink>

          <span className="ml-auto rounded-full bg-black/85 px-3 py-1.5 text-sm font-semibold text-white shadow-md backdrop-blur">
            {labels.results}
          </span>
        </div>

        {/* Right-hand zoom column — decorative, matches the mockup. */}
        <div className="pointer-events-none absolute top-1/2 right-3 z-20 flex -translate-y-1/2 flex-col gap-1.5 sm:right-4">
          <ZoomBadge>
            <Plus className="size-4" aria-hidden />
          </ZoomBadge>
          <ZoomBadge>
            <Minus className="size-4" aria-hidden />
          </ZoomBadge>
        </div>

        {/* Bottom-right: "near me" primary — links straight to the live map. */}
        <Link
          href="/explore#near"
          className="absolute right-3 bottom-3 z-20 inline-flex items-center gap-2 rounded-full bg-white/95 px-4 py-2.5 text-sm font-semibold text-neutral-900 shadow-lg backdrop-blur transition-colors hover:bg-white sm:right-4 sm:bottom-4"
        >
          <Navigation className="size-4" aria-hidden />
          {labels.nearMeCta}
        </Link>

        {/* Bottom-left: mock coordinates strip. Purely decorative — sets the
            "this is a map" tone without pretending to be a real fix. */}
        <div className="pointer-events-none absolute bottom-3 left-3 z-20 hidden font-mono text-[10px] tracking-wider text-neutral-800/70 sm:block">
          41.2995°N 69.2401°E · {labels.cityLabel}
        </div>
      </div>

      {/* Caption under the map — mirrors the mockup, keeps hover behavior
          discoverable on touch and desktop. */}
      <div className="border-border border-t bg-white/60 px-4 py-2 text-center font-mono text-[11px] tracking-wide text-neutral-700 backdrop-blur">
        {labels.pinHint}
      </div>
    </div>
  );
}

function ChipLink({
  href,
  children,
}: {
  href: string;
  children: React.ReactNode;
}) {
  return (
    <Link
      href={href}
      className="pointer-events-auto rounded-full bg-white/95 px-3.5 py-1.5 text-sm font-semibold text-neutral-900 shadow-md ring-1 ring-black/5 backdrop-blur transition-colors hover:bg-white"
    >
      {children}
    </Link>
  );
}

function ZoomBadge({ children }: { children: React.ReactNode }) {
  return (
    <span className="flex size-8 items-center justify-center rounded-md bg-white/95 text-neutral-800 shadow-md ring-1 ring-black/5 backdrop-blur">
      {children}
    </span>
  );
}

function YouAreHere({ label }: { label: string }) {
  return (
    <div className="pointer-events-none absolute inset-0 z-10">
      {/* Concentric dashed rings — the "3 km around me" hint from the mockup. */}
      <span
        aria-hidden
        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full border border-dashed border-neutral-500/30"
        style={{ width: "38%", aspectRatio: "1" }}
      />
      <span
        aria-hidden
        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full border border-dashed border-neutral-500/25"
        style={{ width: "62%", aspectRatio: "1" }}
      />
      {/* Blue dot. */}
      <span
        aria-hidden
        className="absolute top-1/2 left-1/2 block size-3.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#2F6BFF] ring-4 ring-[#2F6BFF]/25"
      />
      {/* Speech-bubble label. */}
      <span className="absolute top-1/2 left-1/2 mt-4 -translate-x-1/2 rounded-md bg-white px-2 py-1 font-mono text-[10px] tracking-wide text-neutral-900 shadow-md ring-1 ring-black/10">
        {label}
      </span>
    </div>
  );
}

function SalaryPin({
  job,
  pill,
  left,
  top,
  open,
  onOpen,
}: {
  job: Job;
  pill: string;
  left: number;
  top: number;
  open: boolean;
  onOpen: () => void;
}) {
  const meta = [job.categoryName, schedulePatternLabel(job.schedulePattern)]
    .filter(Boolean)
    .join(" · ");
  return (
    <div
      className="group absolute z-30"
      style={{ left: `${left}%`, top: `${top}%` }}
    >
      {/* The pin itself. `-translate-y-full` seats the pointer on the anchor. */}
      <button
        type="button"
        onClick={onOpen}
        aria-expanded={open}
        aria-label={`${job.title} — ${pill}`}
        className="-translate-x-1/2 -translate-y-full cursor-pointer"
      >
        <span className="relative block">
          <span className="block whitespace-nowrap rounded-full border-2 border-neutral-900 bg-[#C7FB00] px-2.5 py-1 font-mono text-xs font-bold text-neutral-900 shadow-[0_6px_14px_rgba(0,0,0,0.25)] transition-transform group-hover:-translate-y-0.5">
            {pill}
          </span>
          <span
            aria-hidden
            className="absolute left-1/2 -bottom-[7px] block size-0 -translate-x-1/2 border-x-[6px] border-t-[8px] border-x-transparent border-t-neutral-900"
          />
        </span>
      </button>

      {/* Popup card — hover on desktop, click-toggle on touch. Links to the
          job so a curious visitor lands on the real posting in one tap. */}
      <div
        className={cn(
          "absolute left-1/2 z-40 mt-1 w-64 -translate-x-1/2 rounded-xl border border-neutral-200 bg-white p-3 shadow-2xl transition-opacity",
          "pointer-events-none opacity-0 group-hover:pointer-events-auto group-hover:opacity-100",
          open && "pointer-events-auto opacity-100",
        )}
        // Anchor above the pin so it doesn't cover the pointer.
        style={{ top: "-8px", transform: "translate(-50%, -100%)" }}
      >
        <Link
          href={`/jobs/${job.id}`}
          className="block font-bold text-neutral-900 hover:text-neutral-700"
        >
          {job.title}
        </Link>
        <div className="mt-0.5 text-sm text-neutral-600">
          {job.companyName}
        </div>
        <div className="mt-1 font-mono text-sm font-semibold text-neutral-900">
          {pill}
        </div>
        {meta ? (
          <div className="mt-0.5 text-xs text-neutral-500">{meta}</div>
        ) : null}
      </div>
    </div>
  );
}

function StylizedMap() {
  // City blocks laid out on a soft grid, with small variations so the map
  // doesn't feel machine-perfect. Same shapes in every render (SSR-safe).
  const blocks = [
    // row 1
    { x: 30, y: 30, w: 130, h: 90 },
    { x: 175, y: 30, w: 90, h: 90 },
    { x: 275, y: 30, w: 160, h: 90 },
    { x: 450, y: 30, w: 120, h: 90 },
    { x: 580, y: 30, w: 90, h: 90 },
    { x: 690, y: 30, w: 90, h: 90 },
    // row 2
    { x: 30, y: 135, w: 100, h: 120 },
    { x: 145, y: 135, w: 140, h: 120 },
    { x: 300, y: 135, w: 140, h: 60 },
    { x: 300, y: 210, w: 60, h: 45 },
    { x: 375, y: 210, w: 65, h: 45 },
    { x: 460, y: 135, w: 110, h: 120 },
    { x: 585, y: 135, w: 90, h: 60 },
    { x: 690, y: 135, w: 90, h: 60 },
    { x: 585, y: 210, w: 90, h: 45 },
    { x: 690, y: 210, w: 90, h: 45 },
    // row 3 (thinner)
    { x: 30, y: 275, w: 80, h: 70 },
    { x: 125, y: 275, w: 110, h: 70 },
    { x: 250, y: 275, w: 190, h: 70 },
    { x: 460, y: 275, w: 130, h: 70 },
    { x: 605, y: 275, w: 175, h: 70 },
    // row 4 (bottom)
    { x: 30, y: 360, w: 200, h: 100 },
    { x: 250, y: 360, w: 130, h: 60 },
    { x: 400, y: 360, w: 110, h: 60 },
    { x: 530, y: 360, w: 140, h: 100 },
    { x: 690, y: 360, w: 90, h: 100 },
  ];
  return (
    <>
      {/* Cream base for map itself; uses a fixed light tone so the branded
          pins and river read the same in light and dark. */}
      <rect width={VIEW_W} height={VIEW_H} fill="#F1F1EA" />

      {/* Green park patches (bottom-left corner) — a subtle brand echo. */}
      <path
        d="M20 380 Q 80 350 130 370 T 240 400 L 240 465 L 20 465 Z"
        fill="#C7FB00"
        fillOpacity="0.18"
      />
      <circle cx="60" cy="410" r="4" fill="#C7FB00" fillOpacity="0.6" />
      <circle cx="110" cy="425" r="3" fill="#C7FB00" fillOpacity="0.6" />
      <circle cx="175" cy="415" r="3.5" fill="#C7FB00" fillOpacity="0.6" />

      {/* River hint on the far right. */}
      <path
        d="M780 40 Q 740 140 770 220 T 750 340 Q 760 400 790 470 L 800 470 L 800 30 Z"
        fill="#BFD8FF"
        fillOpacity="0.55"
      />
      <path
        d="M780 40 Q 740 140 770 220 T 750 340 Q 760 400 790 470"
        stroke="#89B4FF"
        strokeWidth="1.2"
        fill="none"
        strokeOpacity="0.6"
      />

      {/* Building blocks — stone-tone, subtly staggered opacity for depth. */}
      {blocks.map((b, i) => (
        <rect
          key={i}
          x={b.x}
          y={b.y}
          width={b.w}
          height={b.h}
          rx={4}
          fill="#D8D8D0"
          fillOpacity={0.55 + ((i * 7) % 4) * 0.06}
        />
      ))}

      {/* Two subway/road hint marks — the tiny ovals from the mockup. */}
      <ellipse cx="446" cy="240" rx="12" ry="4" fill="#8A8A82" fillOpacity="0.8" />
      <ellipse cx="605" cy="240" rx="12" ry="4" fill="#8A8A82" fillOpacity="0.8" />
    </>
  );
}
