"use client";

import dynamic from "next/dynamic";

import type { Job } from "@/lib/data/types";
import { cn } from "@/lib/utils";

import type { MapRatings } from "./jobs-map-inner";

// Leaflet touches `window`, so the map is client-only (no SSR). The skeleton
// fills the sized container below, so it is pixel-identical to the mounted
// map — no jump when the dynamic import resolves.
const Inner = dynamic(() => import("./jobs-map-inner"), {
  ssr: false,
  loading: () => <div className="bg-muted h-full w-full animate-pulse" />,
});

/**
 * Branded "jobs near you" map: volt/ink job-title markers, a you-are-here
 * pin with near-me/salary/schedule filter chips, and a 2-click apply CTA in
 * each pin's card. Shared by the /explore page and the landing map showcase.
 */
export function JobsMap({
  jobs,
  ratings,
  height,
  fullBleed = false,
}: {
  jobs: Job[];
  ratings?: MapRatings;
  height?: string;
  fullBleed?: boolean;
}) {
  // Full-bleed = viewport minus the 64px header, and on phones minus the 56px
  // tab bar too (the body reserves that space, so without subtracting it here
  // the "full screen" map is one tab-bar taller than the screen and the page
  // scrolls). `--tabbar` is 0 from `md` up, where the bar is hidden.
  const mapHeight = fullBleed
    ? "calc(100dvh - 4rem - var(--tabbar))"
    : (height ?? "70vh");
  return (
    <div
      className={cn(
        "relative overflow-hidden",
        !fullBleed && "border-border rounded-2xl border",
      )}
      style={{ height: mapHeight }}
    >
      <Inner jobs={jobs} ratings={ratings} fullBleed={fullBleed} />
    </div>
  );
}
