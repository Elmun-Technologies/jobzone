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
  wheelZoom = true,
  onError,
}: {
  jobs: Located[];
  loc: LatLng | null;
  locale: string;
  applyLabel: string;
  youAreHere: string;
  ratings?: MapRatings;
  /** When false (embedded landing map), the mouse wheel scrolls the page
   * instead of zooming — no scroll-zoom trap. */
  wheelZoom?: boolean;
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
              // No default zoom/geo controls — clean immersive map (our own
              // filter bar sits top-left; scroll/pinch to zoom).
              controls: [],
            },
            { suppressMapOpenBlock: true },
          );
          if (!wheelZoom) map.current.behaviors.disable("scrollZoom");
        } else if (loc) {
          map.current.setCenter([loc.lat, loc.lng], 13);
        }

        // Joyme-style salary price-tag: a volt bubble with a pointer at the
        // point. Always volt (#C7FB00) on ink — high-contrast on Yandex's light
        // tiles, where a white tag washes out; a boosted job is prefixed ★.
        const PinLayout = ymaps.templateLayoutFactory.createClass(
          `<div style="position:relative;transform:translate(-50%,-100%)">
            <div style="background:#C7FB00;color:#0A0A0A;border:2px solid #0A0A0A;border-radius:9999px;padding:5px 11px;font:800 13px/1 monospace;white-space:nowrap;box-shadow:0 4px 12px rgba(0,0,0,.35)">$[properties.label]</div>
            <div style="position:absolute;left:50%;bottom:-7px;transform:translateX(-50%);width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-top:8px solid #0A0A0A"></div>
          </div>`,
        );

        map.current.geoObjects.removeAll();
        for (const job of jobs) {
          const pill = salaryPill(job) ?? "•";
          map.current.geoObjects.add(
            new ymaps.Placemark(
              [job.lat, job.lng],
              {
                label: job.boostActive ? `★ ${pill}` : pill,
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
  }, [jobs, loc, lang, locale, applyLabel, youAreHere, ratings, wheelZoom]);

  useEffect(() => {
    return () => {
      map.current?.destroy();
      map.current = null;
    };
  }, []);

  return <div ref={el} className="h-full w-full" />;
}
