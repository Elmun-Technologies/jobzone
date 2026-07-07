"use client";

import dynamic from "next/dynamic";

// Leaflet touches `window`, so the picker is client-only (no SSR) — same
// pattern as <JobsMap>.
const Inner = dynamic(() => import("./location-picker-inner"), {
  ssr: false,
  loading: () => (
    <div className="bg-muted h-56 w-full animate-pulse rounded-xl" />
  ),
});

/**
 * Click-to-drop-pin location picker for the post-a-job wizard's location
 * step. Persists the picked point as `{lat, lng}` via `onChange`.
 */
export function LocationPicker(props: {
  lat: number | null;
  lng: number | null;
  onChange: (v: { lat: number; lng: number } | null) => void;
  cityHint?: string | null;
  locale: string;
}) {
  return <Inner {...props} />;
}
