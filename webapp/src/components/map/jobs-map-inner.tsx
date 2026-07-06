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

const TASHKENT: [number, number] = [41.3111, 69.2797];
const NEAR_RADIUS_M = 10_000;
const SALARY_FROM = 4_000_000; // "4 mln dan" chip

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
  height = "70vh",
}: {
  jobs: Job[];
  height?: string;
}) {
  const locale = useLocale();
  const t = useTranslations("explore");
  const { loc, status, request } = useUserLocation();
  const [nearMe, setNearMe] = useState(false);
  const [salaryOn, setSalaryOn] = useState(false);
  const [schedule22, setSchedule22] = useState(false);

  const located = useMemo<Located[]>(
    () =>
      jobs
        .filter(
          (j): j is Job & { lat: number; lng: number } =>
            j.lat != null && j.lng != null,
        )
        .map((j) => ({
          ...j,
          distance: loc
            ? haversineMeters(loc, { lat: j.lat, lng: j.lng })
            : null,
        })),
    [jobs, loc],
  );

  const shown = useMemo(
    () =>
      located.filter((j) => {
        if (nearMe && (j.distance == null || j.distance > NEAR_RADIUS_M)) {
          return false;
        }
        if (salaryOn && (j.salaryMax ?? j.salaryMin ?? 0) < SALARY_FROM) {
          return false;
        }
        if (schedule22 && j.schedulePattern !== "2_2") return false;
        return true;
      }),
    [located, nearMe, salaryOn, schedule22],
  );

  function toggleNearMe() {
    if (!nearMe && !loc) request();
    setNearMe((v) => !v);
  }

  return (
    <div
      className="border-border relative overflow-hidden rounded-2xl border"
      style={{ height }}
    >
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
              <PinCard job={j} locale={locale} applyLabel={t("map.apply")} />
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      {/* Filter chips + live count, floated above the map. */}
      <div className="pointer-events-none absolute inset-x-0 top-0 z-[1000] flex flex-wrap items-center gap-2 p-3">
        <Chip
          active={nearMe}
          onClick={toggleNearMe}
          label={status === "locating" ? t("map.locating") : t("map.nearMe")}
        />
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
        <span className="text-foreground bg-background/90 pointer-events-none ml-auto rounded-full px-3 py-1.5 text-sm font-semibold shadow-sm backdrop-blur">
          {t("map.results", { count: shown.length })}
        </span>
      </div>

      {status === "denied" && nearMe ? (
        <div className="text-muted-foreground bg-background/95 absolute inset-x-0 bottom-0 z-[1000] m-3 rounded-lg px-3 py-2 text-center text-sm shadow">
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
        "pointer-events-auto rounded-full border px-3 py-1.5 text-sm font-medium shadow-sm transition-colors",
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
}: {
  job: Located;
  locale: string;
  applyLabel: string;
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
      <div className="text-muted-foreground text-sm">{job.companyName}</div>
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
