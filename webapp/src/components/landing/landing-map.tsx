"use client";

import dynamic from "next/dynamic";

import type { Job } from "@/lib/data/types";

import type { LandingMapLabels } from "./landing-map-inner";

// Leaflet touches `window`, so the map is client-only (no SSR). The skeleton
// fills the same aspect box so the layout doesn't jump when the chunk lands.
const Inner = dynamic(() => import("./landing-map-inner"), {
  ssr: false,
  loading: () => (
    <div
      className="border-border w-full animate-pulse rounded-2xl border bg-[#F1F1EA]"
      style={{ aspectRatio: "16 / 10" }}
    />
  ),
});

export function LandingMap(props: { jobs: Job[]; labels: LandingMapLabels }) {
  return <Inner {...props} />;
}
