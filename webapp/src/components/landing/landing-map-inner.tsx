"use client";

import "leaflet/dist/leaflet.css";

import L from "leaflet";
import { Minus, Navigation, Plus } from "lucide-react";
import { useCallback, useMemo, useState } from "react";
import { MapContainer, Marker, TileLayer } from "react-leaflet";

import { Link, useRouter } from "@/i18n/navigation";
import type { Job } from "@/lib/data/types";
import { salaryPill } from "@/lib/format";
import { jobLatLng } from "@/lib/uz-geo";

import {
  PinCardOverlay,
  usePinHover,
  type PinRating,
} from "../map/job-pin-card";
import { salaryPinIcon } from "../map/pin-icon";
import { mapTier } from "../map/tier";
import { LANDING_MAP_PIN_COUNT } from "./landing-map-shared";
import { LandingYandexMap } from "./landing-yandex-map";

// Tashkent — the map is anchored here and never panned (the whole spot is a
// landing showcase; interaction lives on /explore).
const TASHKENT: [number, number] = [41.3111, 69.2797];
const LANDING_ZOOM = 12;
// A *JavaScript API* key switches the engine to Yandex; empty → OSM/Leaflet
// (same contract as the /explore map in components/map/jobs-map-inner.tsx).
const YANDEX_KEY = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY;

type Labels = {
  chipNearMe: string;
  chipSalary: string;
  chipSchedule: string;
  /** Pre-formatted "N ta vakansiya" string — server can't pass a function
   * into a client component, so the caller resolves the ICU. */
  results: string;
  nearMeCta: string;
  youAreHere: string;
  pinHint: string;
  cityLabel: string;
  negotiable: string;
};

export type LandingMapLabels = Labels;

export default function LandingMapInner({
  jobs,
  labels,
  ratings,
}: {
  /** Already trimmed by pickLandingMapJobs on the server. */
  jobs: Job[];
  labels: Labels;
  /** Live average rating + review count per company id (hover card). */
  ratings?: Record<string, PinRating>;
}) {
  const router = useRouter();
  const [yandexFailed, setYandexFailed] = useState(false);
  const useYandex = !!YANDEX_KEY && !yandexFailed;
  // Hover preview card + click-through over the pins' data-job-id — the same
  // engine-agnostic delegation the /explore map uses.
  const goToJob = useCallback(
    (id: string) => router.push(`/jobs/${id}`),
    [router],
  );
  const { wrapRef, hover, api, handlers } = usePinHover(goToJob);
  // Stable identity: a fresh array every render would re-run the Yandex
  // marker effect on each hover re-render, recreating the hovered pin's DOM
  // under the cursor (and swallowing its mouseout — the card never closes).
  const pinned = useMemo(() => jobs.slice(0, LANDING_MAP_PIN_COUNT), [jobs]);

  // Frame every pin comfortably inside the viewport — with only a few
  // salaried jobs, centering on Tashkent at a fixed zoom leaves the map
  // looking half-empty and stacks the pins under the "you are here" dot.
  const bounds = pinned.length
    ? L.latLngBounds(
        pinned.map((j) => {
          const p = jobLatLng(j);
          return [p.lat, p.lng] as [number, number];
        }),
      ).pad(0.35)
    : null;

  // The "you are here" dot lives at the DOM center rather than a real
  // lat/lng: the map may be framed anywhere in the city and it should
  // always read as "the viewer stands here" regardless.

  return (
    <div className="border-border relative overflow-hidden rounded-2xl border">
      <div
        ref={wrapRef}
        {...handlers}
        // `isolate` traps Leaflet's large internal z-indexes (panes up to
        // 700, our overlays 500-600) inside the map card so they can't stack
        // above page-level overlays like the mobile menu drawer (z-60).
        className="relative isolate w-full"
        style={{ aspectRatio: "16 / 10" }}
      >
        {useYandex ? (
          <LandingYandexMap
            jobs={pinned}
            negotiable={labels.negotiable}
            onPinClick={goToJob}
            hoverApi={api}
            onError={() => setYandexFailed(true)}
          />
        ) : (
          <MapContainer
            {...(bounds
              ? { bounds, boundsOptions: { padding: [30, 30] } }
              : { center: TASHKENT, zoom: LANDING_ZOOM })}
            // Non-interactive on the landing surface — the map is a backdrop,
            // not a driver. All exploration flows through the chips or the
            // /explore link, which sidesteps the scroll-zoom trap for real.
            scrollWheelZoom={false}
            dragging={false}
            doubleClickZoom={false}
            touchZoom={false}
            boxZoom={false}
            keyboard={false}
            zoomControl={false}
            attributionControl={false}
            className="h-full w-full"
            // Ink base while tiles load — the showcase map is dark to match
            // the brand and the /explore map (volt pins pop on ink).
            style={{ background: "#0A0A0A" }}
          >
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution="&copy; OpenStreetMap &copy; CARTO"
            />
            {pinned.map((job) => {
              const pos = jobLatLng(job);
              return (
                <Marker
                  key={job.id}
                  position={[pos.lat, pos.lng]}
                  icon={salaryPinIcon(
                    salaryPill(job) ?? labels.negotiable,
                    job.id,
                    mapTier(job.boostKind),
                  )}
                />
              );
            })}
          </MapContainer>
        )}

        {/* Hover preview — the mockup's card: logo, title, live rating,
            salary chip and one-tap apply. Shared with /explore. */}
        {hover
          ? (() => {
              const j = pinned.find((x) => x.id === hover.jobId);
              return j ? (
                <PinCardOverlay
                  hover={hover}
                  job={j}
                  rating={ratings?.[j.companyId]}
                />
              ) : null;
            })()
          : null}

        {/* "You are here" — DOM overlay so it always sits at the visual
            center regardless of how the map is framed. Blue dot + soft ring
            + speech-bubble caption. */}
        <div className="pointer-events-none absolute inset-0 z-[500]">
          <span
            aria-hidden
            className="absolute top-1/2 left-1/2 block size-3.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#2F6BFF] shadow-[0_0_0_5px_rgba(47,107,255,.22)] ring-[3px] ring-white"
          />
          <span className="absolute top-1/2 left-1/2 mt-4 -translate-x-1/2 rounded-md bg-white/95 px-2 py-1 font-mono text-[10px] tracking-wide text-neutral-900 shadow-md ring-1 ring-black/10 backdrop-blur">
            {labels.youAreHere}
          </span>
        </div>

        {/* Top row — decorative chips linking to /explore with the filter
            applied + a live result count pill on the right. */}
        <div className="pointer-events-none absolute inset-x-3 top-3 z-[600] flex flex-wrap items-start gap-2 sm:inset-x-4 sm:top-4">
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

        {/* Right-hand zoom column — decorative, matches the mockup silhouette. */}
        <div className="pointer-events-none absolute top-1/2 right-3 z-[600] flex -translate-y-1/2 flex-col gap-1.5 sm:right-4">
          <ZoomBadge>
            <Plus className="size-4" aria-hidden />
          </ZoomBadge>
          <ZoomBadge>
            <Minus className="size-4" aria-hidden />
          </ZoomBadge>
        </div>

        {/* Bottom-right: "near me" primary — jumps to the live map. */}
        <Link
          href="/explore#near"
          className="absolute right-3 bottom-3 z-[600] inline-flex items-center gap-2 rounded-full bg-white/95 px-4 py-2.5 text-sm font-semibold text-neutral-900 shadow-lg backdrop-blur transition-colors hover:bg-white sm:right-4 sm:bottom-4"
        >
          <Navigation className="size-4" aria-hidden />
          {labels.nearMeCta}
        </Link>

        {/* Bottom-left: mock coordinate strip — sets the "this is a map" tone
            without pretending to reflect an actual fix. Hidden on the Yandex
            engine, where it would collide with Yandex's own "Open in Yandex
            Maps" link + attribution in that corner. */}
        {!useYandex ? (
          <div className="pointer-events-none absolute bottom-3 left-3 z-[600] hidden font-mono text-[10px] tracking-wider text-neutral-800/80 sm:block">
            41.2995°N 69.2401°E · {labels.cityLabel}
          </div>
        ) : null}
      </div>

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
