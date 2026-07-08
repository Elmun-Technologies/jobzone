"use client";

import { useEffect, useRef } from "react";

import type { Job } from "@/lib/data/types";
import type { LatLng } from "@/lib/geo";
import { salaryPill, salaryText, schedulePatternLabel } from "@/lib/format";
import { loadYmaps, type YmapsMap } from "@/lib/yandex-maps-loader";

import type { MapRatings } from "./jobs-map-inner";

const TASHKENT: [number, number] = [41.3111, 69.2797];

type Located = Job & { lat: number; lng: number };

/** Escape a value before interpolating it into the balloon's HTML string. */
function esc(v: string): string {
  return v
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** Balloon (popup) HTML for a job pin — mirrors the Leaflet PinCard. Yandex
 * renders this string as HTML, so every interpolated value (raw employer text:
 * job title, company name) must be escaped or it's stored XSS. */
function balloonHtml(
  job: Located,
  locale: string,
  applyLabel: string,
  rating?: { avg: number; count: number },
): string {
  const salary = salaryText(job);
  const meta = [job.categoryName, schedulePatternLabel(job.schedulePattern)]
    .filter(Boolean)
    .join(" · ");
  const stars =
    rating && rating.count > 0 ? ` · ⭐ ${rating.avg.toFixed(1)}` : "";
  return `<div style="min-width:190px;font-family:inherit">
    <a href="/${locale}/jobs/${esc(job.id)}" style="display:block;font-weight:700;color:#0A0A0A">${esc(job.title)}</a>
    <div style="color:#666;font-size:13px">${esc(job.companyName)}${esc(stars)}</div>
    ${salary ? `<div style="font-weight:600;font-size:13px;margin-top:2px">${esc(salary)}</div>` : ""}
    ${meta ? `<div style="color:#666;font-size:12px">${esc(meta)}</div>` : ""}
    <a href="/${locale}/jobs/${esc(job.id)}/apply" style="display:inline-block;margin-top:8px;background:#C7FB00;color:#0A0A0A;border-radius:9999px;padding:6px 12px;font-size:13px;font-weight:600;text-decoration:none">${esc(applyLabel)}</a>
  </div>`;
}

/**
 * Yandex Maps (JS API v2.1) renderer — the branded volt/ink salary pins on
 * Yandex tiles. Only mounted when a JS-API key is present; any load/init
 * failure calls `onError` so the parent falls back to the OSM map.
 */
export function YandexMap({
  jobs,
  loc,
  locale,
  applyLabel,
  youAreHere,
  ratings,
  onError,
}: {
  jobs: Located[];
  loc: LatLng | null;
  locale: string;
  applyLabel: string;
  youAreHere: string;
  ratings?: MapRatings;
  onError: () => void;
}) {
  const el = useRef<HTMLDivElement>(null);
  const map = useRef<YmapsMap | null>(null);
  // Keep the latest onError without making it a marker-effect dependency
  // (the parent passes a fresh closure each render).
  const onErrorRef = useRef(onError);
  useEffect(() => {
    onErrorRef.current = onError;
  }, [onError]);
  const lang = locale === "en" ? "en_US" : "ru_RU";

  useEffect(() => {
    let cancelled = false;
    loadYmaps(lang)
      .then((ymaps) => {
        if (cancelled || !el.current) return;
        if (!map.current) {
          map.current = new ymaps.Map(
            el.current,
            {
              center: loc ? [loc.lat, loc.lng] : TASHKENT,
              zoom: loc ? 13 : 11,
              controls: ["zoomControl", "geolocationControl"],
            },
            { suppressMapOpenBlock: true },
          );
        } else if (loc) {
          map.current.setCenter([loc.lat, loc.lng], 13);
        }

        const PinLayout = ymaps.templateLayoutFactory.createClass(
          `<div style="transform:translate(-50%,-100%);background:$[properties.bg];color:#0A0A0A;border:2px solid #0A0A0A;border-radius:9999px;padding:3px 9px;font:700 12px/1 monospace;box-shadow:0 2px 6px rgba(0,0,0,.28);white-space:nowrap">$[properties.label]</div>`,
        );

        map.current.geoObjects.removeAll();
        for (const job of jobs) {
          map.current.geoObjects.add(
            new ymaps.Placemark(
              [job.lat, job.lng],
              {
                label: salaryPill(job) ?? "•",
                bg: job.boostActive ? "#C7FB00" : "#FFFFFF",
                balloonContent: balloonHtml(
                  job,
                  locale,
                  applyLabel,
                  ratings?.[job.companyId],
                ),
              },
              { iconLayout: PinLayout, iconShape: null },
            ),
          );
        }
        if (loc) {
          map.current.geoObjects.add(
            new ymaps.Placemark(
              [loc.lat, loc.lng],
              { balloonContent: youAreHere },
              { preset: "islands#blueCircleDotIcon" },
            ),
          );
        }
      })
      .catch((e) => {
        console.error("Yandex map failed, falling back to OSM", e);
        if (!cancelled) onErrorRef.current();
      });
    return () => {
      cancelled = true;
    };
  }, [jobs, loc, lang, locale, applyLabel, youAreHere, ratings]);

  useEffect(() => {
    return () => {
      map.current?.destroy();
      map.current = null;
    };
  }, []);

  return <div ref={el} className="h-full w-full" />;
}
