"use client";

import "leaflet/dist/leaflet.css";

import L from "leaflet";
import { Moon, Navigation, Search, Sun, X } from "lucide-react";
import { useLocale, useTranslations } from "next-intl";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  MapContainer,
  Marker,
  Popup,
  TileLayer,
  ZoomControl,
  useMap,
} from "react-leaflet";

import { useRouter } from "@/i18n/navigation";
import type { Job } from "@/lib/data/types";
import { salaryPill } from "@/lib/format";
import { haversineMeters, useUserLocation, type LatLng } from "@/lib/geo";
import { cn } from "@/lib/utils";
import { jobLatLng } from "@/lib/uz-geo";

import { PinCardOverlay, usePinHover } from "./job-pin-card";
import { salaryPinIcon } from "./pin-icon";
import { mapTier } from "./tier";
import { YandexMap } from "./yandex-map";

/** Average rating + review count per company id (map "by rating" facet). */
export type MapRatings = Record<string, { avg: number; count: number }>;

const TASHKENT: [number, number] = [41.3111, 69.2797];
const NEAR_RADIUS_M = 10_000;
const SALARY_FROM = 4_000_000; // "4 mln dan" chip
const TOP_RATED_MIN = 4; // avg rating for the "gullar" / top-rated facet
// Job-type segment tabs (Joyme's Sotuv/Ijara/Kunlik analogue). "" = all;
// order puts the blue-collar-relevant types first, the row scrolls for the
// rest. Labels come from the shared `jobs.type.*` catalogue.
const JOB_TYPES = [
  "",
  "full_time",
  "part_time",
  "rotational",
  "contract",
  "temporary",
  "internship",
] as const;
// A *JavaScript API* key switches the engine to Yandex; empty → OSM/Leaflet.
const YANDEX_KEY = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY;

type Located = Job & { lat: number; lng: number; distance: number | null };

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
  fullBleed = false,
}: {
  jobs: Job[];
  ratings?: MapRatings;
  /** Immersive mode (the /explore "map search"): wheel-zoom stays enabled;
   * the embedded landing map disables it so the page can scroll past. The
   * sizing container lives in JobsMap. */
  fullBleed?: boolean;
}) {
  const locale = useLocale();
  const t = useTranslations("explore");
  const tj = useTranslations("jobs");
  const router = useRouter();
  // Hover preview card + click-through, via DOM delegation over the pins'
  // data-job-id — engine-agnostic (works for Yandex and Leaflet alike).
  const goToJob = useCallback(
    (id: string) => router.push(`/jobs/${id}`),
    [router],
  );
  const { wrapRef, hover, api, handlers } = usePinHover(goToJob);
  const { loc, status, request } = useUserLocation();
  const [nearMe, setNearMe] = useState(false);
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("");
  const [company, setCompany] = useState("");
  const [topRated, setTopRated] = useState(false);
  const [salaryOn, setSalaryOn] = useState(false);
  const [schedule22, setSchedule22] = useState(false);
  const [jobType, setJobType] = useState("");
  const [yandexFailed, setYandexFailed] = useState(false);
  // Dark base map by default — the Joyme-style ink map that makes the volt
  // salary pins pop and matches the brand. The ☀️/🌙 button flips it. Only the
  // OSM/Leaflet engine themes this way (Yandex JS has no clean night mode).
  const [mapDark, setMapDark] = useState(true);
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
        if (jobType && j.jobType !== jobType) return false;
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
      jobType,
      ratings,
    ],
  );

  function toggleNearMe() {
    if (!nearMe && !loc) request();
    setNearMe((v) => !v);
  }

  const selectCls =
    "border-border bg-background/95 text-foreground h-9 rounded-full border px-3 text-sm font-medium shadow-sm outline-none focus-visible:ring-2 focus-visible:ring-ring";

  return (
    // `isolate` keeps Leaflet panes + our z-[1000] controls from stacking
    // above page-level overlays (mobile menu drawer, dialogs).
    <div ref={wrapRef} {...handlers} className="relative isolate h-full w-full">
      {useYandex ? (
        <YandexMap
          jobs={shown}
          loc={loc}
          locale={locale}
          youAreHere={t("map.youAreHere")}
          negotiable={tj("negotiable")}
          onPinClick={goToJob}
          hoverApi={api}
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
            // CartoDB Dark Matter for the ink map; light OSM when toggled off.
            url={
              mapDark
                ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            }
            attribution={
              mapDark
                ? '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>'
                : '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            }
          />
          {/* Zoom +/- buttons — the map must stay controllable when wheel-zoom
              is off (embedded landing map) or on touch devices. */}
          <ZoomControl position="bottomright" />

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
              icon={salaryPinIcon(
                salaryPill(j) ?? tj("negotiable"),
                j.id,
                mapTier(j.boostKind),
              )}
            />
          ))}
        </MapContainer>
      )}

      {/* Hover preview — the mockup's card: logo, title, live rating, salary
          chip and one-tap apply. Positioned at the hovered pin, shared by
          both engines. */}
      {hover
        ? (() => {
            const j = shown.find((x) => x.id === hover.jobId);
            return j ? (
              <PinCardOverlay
                hover={hover}
                job={j}
                rating={ratings?.[j.companyId]}
                distance={j.distance}
              />
            ) : null;
          })()
        : null}

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
        {/* Job-type segment tabs (Joyme's Sotuv/Ijara/Kunlik analogue) —
            filter the pins by employment type; the row scrolls for the rest. */}
        <div className="pointer-events-auto mt-2 flex [scrollbar-width:none] items-center gap-1.5 overflow-x-auto pb-1 [&::-webkit-scrollbar]:hidden">
          {JOB_TYPES.map((jt) => (
            <button
              key={jt || "all"}
              type="button"
              onClick={() => setJobType(jt)}
              className={cn(
                "shrink-0 rounded-full px-4 py-1.5 text-sm font-semibold shadow-sm transition-colors",
                jobType === jt
                  ? "bg-primary text-primary-foreground"
                  : "border-border bg-background/95 text-foreground border",
              )}
            >
              {jt === "" ? t("map.allTypes") : tj(`type.${jt}`)}
            </button>
          ))}
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
      <div className="absolute top-28 right-3 z-[1001]">
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
          // bottom-24 keeps it clear of the bottom-right zoom control.
          "absolute right-4 bottom-24 z-[1001] flex items-center gap-2 rounded-full px-4 py-3 text-sm font-bold shadow-lg transition-colors",
          nearMe
            ? "bg-primary text-primary-foreground"
            : "bg-background text-foreground border-border border",
        )}
      >
        <Navigation className="size-4" aria-hidden />
        {status === "locating" ? t("map.locating") : t("map.nearMe")}
      </button>

      {/* Light/dark base-map toggle — OSM engine only (Yandex JS has no clean
          night mode). Sits above "near me", bottom-right like the reference. */}
      {!useYandex ? (
        <button
          type="button"
          onClick={() => setMapDark((v) => !v)}
          aria-label={t("map.mapTheme")}
          className="border-border bg-background text-foreground absolute right-4 bottom-40 z-[1001] flex size-11 items-center justify-center rounded-full border shadow-lg"
        >
          {mapDark ? (
            <Sun className="size-5" aria-hidden />
          ) : (
            <Moon className="size-5" aria-hidden />
          )}
        </button>
      ) : null}

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
