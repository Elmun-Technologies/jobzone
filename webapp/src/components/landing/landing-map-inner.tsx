"use client";

import "leaflet/dist/leaflet.css";

import L from "leaflet";
import { Minus, Navigation, Plus } from "lucide-react";
import { useLocale } from "next-intl";
import { useState } from "react";
import { MapContainer, Marker, TileLayer } from "react-leaflet";

import { Link } from "@/i18n/navigation";
import type { Job } from "@/lib/data/types";
import { salaryPill, schedulePatternLabel } from "@/lib/format";
import { jobLatLng } from "@/lib/uz-geo";

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

function escHtml(v: string): string {
  return v
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** Volt salary bubble (like the mockup): rounded pill + downward pointer.
 * `iconSize:[0,0]` collapses Leaflet's wrapper so its own bounding box never
 * clips the pill — instead the pill is an inline-block that sizes to its
 * content, translated up-and-left so the tip sits on the marker anchor. */
function salaryIcon(pill: string): L.DivIcon {
  const text = escHtml(pill);
  return L.divIcon({
    className: "yolla-landing-pin",
    html: `<div style="position:relative;display:inline-block;white-space:nowrap;transform:translate(-50%,-100%);will-change:transform">
      <span style="display:inline-block;background:#C7FB00;color:#0A0A0A;border:2px solid #0A0A0A;border-radius:9999px;
        padding:4px 10px;font-weight:700;font-size:12px;line-height:1.15;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
        box-shadow:0 6px 14px rgba(0,0,0,.28)">${text}</span>
      <span style="position:absolute;left:50%;top:100%;transform:translate(-50%,-1px);width:0;height:0;
        border-left:6px solid transparent;border-right:6px solid transparent;border-top:7px solid #0A0A0A"></span>
    </div>`,
    iconSize: [0, 0],
    iconAnchor: [0, 0],
  });
}

export type LandingMapLabels = Labels;

export default function LandingMapInner({
  jobs,
  labels,
}: {
  /** Already trimmed by pickLandingMapJobs on the server. */
  jobs: Job[];
  labels: Labels;
}) {
  const locale = useLocale();
  const [yandexFailed, setYandexFailed] = useState(false);
  const useYandex = !!YANDEX_KEY && !yandexFailed;
  const pinned = jobs.slice(0, LANDING_MAP_PIN_COUNT);

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
      <div className="relative w-full" style={{ aspectRatio: "16 / 10" }}>
        {useYandex ? (
          <LandingYandexMap
            jobs={pinned}
            negotiable={labels.negotiable}
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
            style={{ background: "#F1F1EA" }}
          >
            <TileLayer
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              attribution="&copy; OpenStreetMap"
            />
            {pinned.map((job) => {
              const pos = jobLatLng(job);
              const pill = salaryPill(job) ?? labels.negotiable;
              const meta = [
                job.categoryName,
                schedulePatternLabel(job.schedulePattern),
              ]
                .filter(Boolean)
                .join(" · ");
              return (
                <Marker
                  key={job.id}
                  position={[pos.lat, pos.lng]}
                  icon={salaryIcon(pill)}
                  // Route through the app's job page rather than opening a
                  // Leaflet popup — every pin should feel like a link to
                  // the real posting on the landing surface.
                  eventHandlers={{
                    click: () => {
                      window.location.href = `/${locale}/jobs/${job.id}`;
                    },
                  }}
                  title={`${job.title} · ${job.companyName}${meta ? " · " + meta : ""}`}
                />
              );
            })}
          </MapContainer>
        )}

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
            without pretending to reflect an actual fix. */}
        <div className="pointer-events-none absolute bottom-3 left-3 z-[600] hidden font-mono text-[10px] tracking-wider text-neutral-800/80 sm:block">
          41.2995°N 69.2401°E · {labels.cityLabel}
        </div>
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
