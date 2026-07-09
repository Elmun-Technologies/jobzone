"use client";

import "leaflet/dist/leaflet.css";

import L from "leaflet";
import { Search, X } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo, useState } from "react";
import { MapContainer, Marker, Popup, TileLayer, useMap } from "react-leaflet";

import { QuickApplyButton } from "@/components/jobs/quick-apply-button";
import type { Job } from "@/lib/data/types";
import {
  formatDistanceMeters,
  salaryPill,
  salaryText,
  schedulePatternLabel,
} from "@/lib/format";
import { haversineMeters, useUserLocation, type LatLng } from "@/lib/geo";
import { cn } from "@/lib/utils";
import { jobLatLng } from "@/lib/uz-geo";

import { YandexMap } from "./yandex-map";

/** Average rating + review count per company id (map "by rating" facet). */
export type MapRatings = Record<string, { avg: number; count: number }>;

const TASHKENT: [number, number] = [41.3111, 69.2797];
const NEAR_RADIUS_M = 10_000;
const SALARY_FROM = 4_000_000; // "4 mln dan" chip
const TOP_RATED_MIN = 4; // avg rating for the "gullar" / top-rated facet
// A *JavaScript API* key switches the engine to Yandex; empty → OSM/Leaflet.
const YANDEX_KEY = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY;

type Located = Job & { lat: number; lng: number; distance: number | null };

/** A Joyme-style salary price-tag pin (bubble + pointer), or a dot when the
 * job has no salary. Every pin is volt on ink — high-contrast on any tile
 * (white pins washed out on light Yandex tiles); a boosted job gets a ★. */
function pinIcon(label: string | null, boosted: boolean): L.DivIcon {
  if (!label) {
    return L.divIcon({
      className: "",
      html: `<span style="display:block;width:15px;height:15px;border-radius:9999px;
        transform:translate(-50%,-50%);background:#C7FB00;border:2px solid #0A0A0A;
        box-shadow:0 2px 7px rgba(0,0,0,.4)"></span>`,
      iconSize: [0, 0],
      iconAnchor: [0, 0],
    });
  }
  const text = boosted ? `★ ${label}` : label;
  return L.divIcon({
    className: "",
    html: `<div style="position:relative;transform:translate(-50%,-100%)">
      <div style="background:#C7FB00;color:#0A0A0A;border:2px solid #0A0A0A;border-radius:9999px;
        padding:5px 11px;font:800 13px/1 var(--font-mono,ui-monospace,monospace);
        white-space:nowrap;box-shadow:0 4px 12px rgba(0,0,0,.35)">${text}</div>
      <div style="position:absolute;left:50%;bottom:-7px;transform:translateX(-50%);width:0;height:0;
        border-left:6px solid transparent;border-right:6px solid transparent;border-top:8px solid #0A0A0A"></div>
    </div>`,
    iconSize: [0, 0],
    iconAnchor: [0, 0],
  });
}

const meIcon = L.divIcon({
  className: "",
  html: `<span style="display:block;width:16px;height:16px;border-radius:9999px;
    transform:translate(-50%,-50%);background:#2F6BFF;border:3px solid #fff;
    box-shadow:0 0 0 4px rgba(47,107,255,.25)"></span>`,
  iconSize: [0, 0],
  iconAnchor: [0, 0],
});

/** Flies the map to the user once their location resolves. */
function Recenter({ to, zoom }: { to: LatLng | null; zoom: number }) {
  const map = useMap();
  useEffect(() => {
    if (to) map.flyTo([to.lat, to.lng], zoom, { duration: 0.8 });
  }, [to, zoom, map]);
  return null;
}

export default function JobsMapInner({
  jobs,
  ratings,
  height = "70vh",
  fullBleed = false,
}: {
  jobs: Job[];
  ratings?: MapRatings;
  height?: string;
  /** Immersive mode: the map fills the viewport and the filters + near-me
   * float over it (the /explore "map search" experience, Joyme-style). */
  fullBleed?: boolean;
}) {
  const locale = useLocale();
  const t = useTranslations("explore");
  const { loc, status, request } = useUserLocation();
  const [nearMe, setNearMe] = useState(false);
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("");
  const [company, setCompany] = useState("");
  const [topRated, setTopRated] = useState(false);
  const [salaryOn, setSalaryOn] = useState(false);
  const [schedule22, setSchedule22] = useState(false);
  const [yandexFailed, setYandexFailed] = useState(false);
  const useYandex = !!YANDEX_KEY && !yandexFailed;

  const hasRatings = ratings != null && Object.keys(ratings).length > 0;

  const located = useMemo<Located[]>(
    () =>
      // Every job resolves to a point (exact pin, city centroid, or Tashkent),
      // so an open job is never dropped from the map.
      jobs.map((j) => {
        const pos = jobLatLng(j);
        return {
          ...j,
          lat: pos.lat,
          lng: pos.lng,
          distance: loc ? haversineMeters(loc, pos) : null,
        };
      }),
    [jobs, loc],
  );

  // Facet options derived from the jobs actually on the map.
  const categories = useMemo(
    () =>
      [
        ...new Set(located.map((j) => j.categoryName).filter(Boolean)),
      ].sort() as string[],
    [located],
  );
  const companies = useMemo(() => {
    const seen = new Map<string, string>();
    for (const j of located)
      if (!seen.has(j.companyId)) seen.set(j.companyId, j.companyName);
    return [...seen.entries()]
      .map(([id, name]) => ({ id, name }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [located]);

  const q = query.trim().toLowerCase();
  const shown = useMemo(
    () =>
      located.filter((j) => {
        if (
          q &&
          !j.title.toLowerCase().includes(q) &&
          !j.companyName.toLowerCase().includes(q) &&
          !(j.categoryName ?? "").toLowerCase().includes(q)
        ) {
          return false;
        }
        if (nearMe && (j.distance == null || j.distance > NEAR_RADIUS_M)) {
          return false;
        }
        if (category && j.categoryName !== category) return false;
        if (company && j.companyId !== company) return false;
        if (topRated && (ratings?.[j.companyId]?.avg ?? 0) < TOP_RATED_MIN) {
          return false;
        }
        if (salaryOn && (j.salaryMax ?? j.salaryMin ?? 0) < SALARY_FROM) {
          return false;
        }
        if (schedule22 && j.schedulePattern !== "2_2") return false;
        return true;
      }),
    [
      located,
      q,
      nearMe,
      category,
      company,
      topRated,
      salaryOn,
      schedule22,
      ratings,
    ],
  );

  function toggleNearMe() {
    if (!nearMe && !loc) request();
    setNearMe((v) => !v);
  }

  const selectCls =
    "border-border bg-background/95 text-foreground h-9 rounded-full border px-3 text-sm font-medium shadow-sm outline-none focus-visible:ring-2 focus-visible:ring-ring";

  const mapHeight = fullBleed ? "calc(100dvh - 4rem)" : height;

  return (
    <div
      className={cn(
        "relative overflow-hidden",
        fullBleed ? "" : "border-border rounded-2xl border",
      )}
      style={{ height: mapHeight }}
    >
      {useYandex ? (
        <YandexMap
          jobs={shown}
          loc={loc}
          locale={locale}
          applyLabel={t("map.apply")}
          youAreHere={t("map.youAreHere")}
          ratings={ratings}
          // Only the immersive /explore map wheel-zooms; the embedded landing
          // map must let the page scroll past it (no scroll-zoom trap).
          wheelZoom={fullBleed}
          onError={() => setYandexFailed(true)}
        />
      ) : (
        <MapContainer
          center={loc ? [loc.lat, loc.lng] : TASHKENT}
          zoom={loc ? 13 : 11}
          scrollWheelZoom={fullBleed}
          zoomControl={false}
          className="h-full w-full"
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          />

          {loc ? (
            <>
              <Recenter to={loc} zoom={13} />
              <Marker position={[loc.lat, loc.lng]} icon={meIcon}>
                <Popup>{t("map.youAreHere")}</Popup>
              </Marker>
            </>
          ) : null}

          {shown.map((j) => (
            <Marker
              key={j.id}
              position={[j.lat, j.lng]}
              icon={pinIcon(salaryPill(j), j.boostActive)}
            >
              <Popup>
                <PinCard
                  job={j}
                  locale={locale}
                  rating={ratings?.[j.companyId]}
                />
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      )}

      {/* Search-on-map bar (Joyme-style: a full-width search row sits above
          the filter-chip row) — searches title/company/category over the jobs
          already on the map, no extra round trip. */}
      <div className="pointer-events-none absolute inset-x-0 top-3 z-[1000] px-3">
        <div className="pointer-events-auto relative">
          <Search className="text-muted-foreground pointer-events-none absolute top-1/2 left-3.5 size-4 -translate-y-1/2" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={t("map.searchPlaceholder")}
            aria-label={t("map.searchPlaceholder")}
            className="border-border bg-background/95 text-foreground placeholder:text-muted-foreground focus-visible:ring-ring h-11 w-full rounded-full border pr-10 pl-10 text-sm shadow-sm outline-none focus-visible:ring-2"
          />
          {query ? (
            <button
              type="button"
              onClick={() => setQuery("")}
              aria-label={t("map.clearSearch")}
              className="text-muted-foreground hover:text-foreground absolute top-1/2 right-3 -translate-y-1/2"
            >
              <X className="size-4" />
            </button>
          ) : null}
        </div>
        <div className="pointer-events-auto mt-2 flex [scrollbar-width:none] items-center gap-2 overflow-x-auto pb-1 [&::-webkit-scrollbar]:hidden">
          <Chip
            active={nearMe}
            onClick={toggleNearMe}
            label={status === "locating" ? t("map.locating") : t("map.nearMe")}
          />
          {categories.length > 0 ? (
            <select
              aria-label={t("map.byCategory")}
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className={cn(
                selectCls,
                "shrink-0",
                category && "border-primary",
              )}
            >
              <option value="">{t("map.allCategories")}</option>
              {categories.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          ) : null}
          {companies.length > 1 ? (
            <select
              aria-label={t("map.byCompany")}
              value={company}
              onChange={(e) => setCompany(e.target.value)}
              className={cn(selectCls, "shrink-0", company && "border-primary")}
            >
              <option value="">{t("map.allCompanies")}</option>
              {companies.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          ) : null}
          {hasRatings ? (
            <Chip
              active={topRated}
              onClick={() => setTopRated((v) => !v)}
              label={`🌸 ${t("map.topRated")}`}
            />
          ) : null}
          <Chip
            active={salaryOn}
            onClick={() => setSalaryOn((v) => !v)}
            label={t("map.salaryFrom")}
          />
          <Chip
            active={schedule22}
            onClick={() => setSchedule22((v) => !v)}
            label={t("map.schedule22")}
          />
        </div>
      </div>

      {/* Live result count (top-right pill). */}
      {/* Below the search bar + chip row now that the search bar spans full
          width (it used to sit beside the chip row at the same top-3 level). */}
      <div className="absolute top-24 right-3 z-[1001]">
        <span className="bg-foreground text-background rounded-full px-3 py-1.5 text-sm font-semibold shadow-md">
          {t("map.results", { count: shown.length })}
        </span>
      </div>

      {/* Prominent "near me" — the fastest path to nearby jobs. */}
      <button
        type="button"
        onClick={toggleNearMe}
        aria-pressed={nearMe}
        className={cn(
          "absolute right-4 bottom-6 z-[1001] flex items-center gap-2 rounded-full px-4 py-3 text-sm font-bold shadow-lg transition-colors",
          nearMe
            ? "bg-primary text-primary-foreground"
            : "bg-background text-foreground border-border border",
        )}
      >
        <span aria-hidden>📍</span>
        {status === "locating" ? t("map.locating") : t("map.nearMe")}
      </button>

      {shown.length === 0 ? (
        <div className="pointer-events-none absolute inset-0 z-[1000] flex items-center justify-center p-6">
          <p className="bg-background/95 text-foreground max-w-xs rounded-xl px-4 py-3 text-center text-sm font-medium shadow">
            {located.length === 0
              ? t("map.emptyNoJobs")
              : t("map.emptyFiltered")}
          </p>
        </div>
      ) : null}

      {status === "denied" && nearMe ? (
        <div className="text-muted-foreground bg-background/95 absolute inset-x-0 bottom-24 z-[1000] mx-3 rounded-lg px-3 py-2 text-center text-sm shadow">
          {t("map.locationDenied")}
        </div>
      ) : null}
    </div>
  );
}

function Chip({
  active,
  label,
  onClick,
}: {
  active: boolean;
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={onClick}
      className={cn(
        "rounded-full border px-3 py-1.5 text-sm font-medium shadow-sm transition-colors",
        active
          ? "border-primary bg-primary text-primary-foreground"
          : "border-border bg-background text-foreground hover:border-primary/40",
      )}
    >
      {label}
    </button>
  );
}

function PinCard({
  job,
  locale,
  rating,
}: {
  job: Located;
  locale: string;
  rating?: { avg: number; count: number };
}) {
  const meta = [
    job.categoryName,
    job.distance != null ? formatDistanceMeters(job.distance) : null,
    schedulePatternLabel(job.schedulePattern),
  ]
    .filter(Boolean)
    .join(" · ");
  const salary = salaryText(job);

  return (
    <div className="min-w-[190px]">
      <a
        href={`/${locale}/jobs/${job.id}`}
        className="text-foreground hover:text-primary block font-bold"
      >
        {job.title}
      </a>
      <div className="text-muted-foreground flex items-center gap-1.5 text-sm">
        {job.companyName}
        {rating && rating.count > 0 ? (
          <span className="text-foreground font-medium">
            · ⭐ {rating.avg.toFixed(1)}
          </span>
        ) : null}
      </div>
      {salary ? (
        <div className="text-foreground mt-0.5 font-mono text-sm font-semibold">
          {salary}
        </div>
      ) : null}
      {meta ? (
        <div className="text-muted-foreground text-xs">{meta}</div>
      ) : null}
      {/* One-tap apply straight from the pin — the map's core promise. Falls
          back to the full form for a job with required screening. */}
      <QuickApplyButton
        jobId={job.id}
        needsForm={job.screeningQuestions.some((q) => q.required)}
        className="mt-2 px-3 py-1.5 text-sm"
      />
    </div>
  );
}
