"use client";

import "leaflet/dist/leaflet.css";

import L from "leaflet";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo, useState } from "react";
import { MapContainer, Marker, Popup, TileLayer, useMap } from "react-leaflet";

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

/** A branded volt/ink map marker showing the compact salary (or a dot). */
function pinIcon(label: string | null, boosted: boolean): L.DivIcon {
  const bg = boosted ? "#C7FB00" : "#FFFFFF";
  const text = label ?? "•";
  return L.divIcon({
    className: "",
    html: `<span style="display:inline-flex;align-items:center;justify-content:center;
      transform:translate(-50%,-100%);background:${bg};color:#0A0A0A;
      border:2px solid #0A0A0A;border-radius:9999px;padding:3px 9px;
      font:700 12px/1 var(--font-mono,ui-monospace,monospace);
      box-shadow:0 2px 6px rgba(0,0,0,.28);white-space:nowrap">${text}</span>`,
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
}: {
  jobs: Job[];
  ratings?: MapRatings;
  height?: string;
}) {
  const locale = useLocale();
  const t = useTranslations("explore");
  const { loc, status, request } = useUserLocation();
  const [nearMe, setNearMe] = useState(false);
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

  const shown = useMemo(
    () =>
      located.filter((j) => {
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
    "border-border bg-background text-foreground h-9 rounded-full border px-3 text-sm font-medium outline-none focus-visible:ring-2 focus-visible:ring-ring";

  return (
    <div>
      {/* Segmentation toolbar — find a job by area, field, company or rating. */}
      <div className="mb-2 flex flex-wrap items-center gap-2">
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
            className={cn(selectCls, category && "border-primary")}
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
            className={cn(selectCls, company && "border-primary")}
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
        <span className="text-foreground bg-muted ml-auto rounded-full px-3 py-1.5 text-sm font-semibold">
          {t("map.results", { count: shown.length })}
        </span>
      </div>

      <p className="text-muted-foreground mb-3 text-xs">{t("map.hint")}</p>

      <div
        className="border-border relative overflow-hidden rounded-2xl border"
        style={{ height }}
      >
        {useYandex ? (
          <YandexMap
            jobs={shown}
            loc={loc}
            locale={locale}
            applyLabel={t("map.apply")}
            youAreHere={t("map.youAreHere")}
            ratings={ratings}
            onError={() => setYandexFailed(true)}
          />
        ) : (
          <MapContainer
            center={loc ? [loc.lat, loc.lng] : TASHKENT}
            zoom={loc ? 13 : 11}
            scrollWheelZoom
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
                    applyLabel={t("map.apply")}
                    rating={ratings?.[j.companyId]}
                  />
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        )}

        {status === "denied" && nearMe ? (
          <div className="text-muted-foreground bg-background/95 absolute inset-x-0 bottom-0 z-[1000] m-3 rounded-lg px-3 py-2 text-center text-sm shadow">
            {t("map.locationDenied")}
          </div>
        ) : null}
      </div>
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
  applyLabel,
  rating,
}: {
  job: Located;
  locale: string;
  applyLabel: string;
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
      <a
        href={`/${locale}/jobs/${job.id}/apply`}
        className="bg-primary text-primary-foreground mt-2 inline-flex items-center rounded-full px-3 py-1.5 text-sm font-semibold hover:opacity-90"
      >
        {applyLabel}
      </a>
    </div>
  );
}
