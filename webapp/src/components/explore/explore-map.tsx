"use client";

import dynamic from "next/dynamic";

import type { Job } from "@/lib/data/types";

// Leaflet touches `window`, so the map is client-only (no SSR).
const Inner = dynamic(() => import("./explore-map-inner"), {
  ssr: false,
  loading: () => (
    <div className="bg-muted h-[70vh] w-full animate-pulse rounded-xl" />
  ),
});

export function ExploreMap({ jobs }: { jobs: Job[] }) {
  return <Inner jobs={jobs} />;
}
