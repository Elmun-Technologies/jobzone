"use client";

import dynamic from "next/dynamic";

import type { Job } from "@/lib/data/types";

// Leaflet touches `window`, so the map is client-only (no SSR).
const Inner = dynamic(() => import("./jobs-map-inner"), {
  ssr: false,
  loading: () => (
    <div className="bg-muted h-[70vh] w-full animate-pulse rounded-2xl" />
  ),
});

/**
 * Branded "jobs near you" map: volt/ink salary-pill markers, a you-are-here
 * pin with near-me/salary/schedule filter chips, and a 2-click apply CTA in
 * each pin's card. Shared by the /explore page and the landing map showcase.
 */
export function JobsMap({ jobs, height }: { jobs: Job[]; height?: string }) {
  return <Inner jobs={jobs} height={height} />;
}
