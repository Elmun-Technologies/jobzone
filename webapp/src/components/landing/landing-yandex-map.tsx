"use client";

import { useLocale } from "next-intl";
import { useEffect, useRef } from "react";

import type { Job } from "@/lib/data/types";
import { salaryPill, schedulePatternLabel } from "@/lib/format";
import { jobLatLng } from "@/lib/uz-geo";
import { loadYmaps, type YmapsMap } from "@/lib/yandex-maps-loader";

// Tashkent — fallback framing when no pin resolves to a point.
const TASHKENT: [number, number] = [41.3111, 69.2797];
const LANDING_ZOOM = 12;

/** Escape a value before it lands in a Yandex hint's HTML string. */
function esc(v: string): string {
  return v
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Yandex-tiles engine for the landing showcase — the same volt salary pills
 * and non-interactive "poster" framing as the Leaflet/OSM version in
 * landing-map-inner.tsx, on real Yandex cartography. Mounted only when a
 * JS-API key is present; any load/init failure calls `onError` so the parent
 * falls back to OSM. All chrome (chips, count pill, "you are here", zoom
 * column, CTA) is DOM-overlaid by the parent and engine-agnostic.
 */
export function LandingYandexMap({
  jobs,
  negotiable,
  onError,
}: {
  /** Already trimmed by pickLandingMapJobs on the server. */
  jobs: Job[];
  /** Pill text for a job without a stated salary. */
  negotiable: string;
  onError: () => void;
}) {
  const locale = useLocale();
  const el = useRef<HTMLDivElement>(null);
  const map = useRef<YmapsMap | null>(null);
  // Keep the latest onError without making it an effect dependency (the
  // parent passes a fresh closure each render).
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
            { center: TASHKENT, zoom: LANDING_ZOOM, controls: [] },
            { suppressMapOpenBlock: true },
          );
          // Non-interactive on the landing surface — the map is a backdrop,
          // not a driver (mirrors the Leaflet poster: no drag/zoom, so the
          // scroll-zoom trap can't fire and touch-scroll passes through).
          for (const b of [
            "drag",
            "scrollZoom",
            "dblClickZoom",
            "multiTouch",
            "rightMouseButtonMagnifier",
          ]) {
            map.current.behaviors.disable(b);
          }
        }

        // Volt salary bubble (like the mockup): rounded pill + downward
        // pointer, tip on the point. $[properties.pill] is HTML-escaped by
        // Yandex's template substitution.
        const PillLayout = ymaps.templateLayoutFactory.createClass(
          `<div style="position:relative;display:inline-block;white-space:nowrap;transform:translate(-50%,-100%)">
            <span style="display:inline-block;background:#C7FB00;color:#0A0A0A;border:2px solid #0A0A0A;border-radius:9999px;padding:4px 10px;font-weight:700;font-size:12px;line-height:1.15;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;box-shadow:0 6px 14px rgba(0,0,0,.28)">$[properties.pill]</span>
            <span style="position:absolute;left:50%;top:100%;transform:translate(-50%,-1px);width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-top:7px solid #0A0A0A"></span>
          </div>`,
        );
        // Clickable hit area matching the pill's box (above the anchor point).
        const pinShape = {
          type: "Rectangle" as const,
          coordinates: [
            [-50, -40],
            [50, 2],
          ],
        };

        map.current.geoObjects.removeAll();
        const points: [number, number][] = [];
        for (const job of jobs) {
          const pos = jobLatLng(job);
          points.push([pos.lat, pos.lng]);
          const meta = [
            job.categoryName,
            schedulePatternLabel(job.schedulePattern),
          ]
            .filter(Boolean)
            .join(" · ");
          const placemark = new ymaps.Placemark(
            [pos.lat, pos.lng],
            {
              pill: salaryPill(job) ?? negotiable,
              hintContent: esc(
                `${job.title} · ${job.companyName}${meta ? " · " + meta : ""}`,
              ),
            },
            { iconLayout: PillLayout, iconShape: pinShape },
          );
          // Route through the app's job page rather than opening a balloon —
          // every pin should feel like a link to the real posting.
          placemark.events.add("click", () => {
            window.location.href = `/${locale}/jobs/${job.id}`;
          });
          map.current.geoObjects.add(placemark);
        }

        // Frame every pin comfortably inside the viewport (parity with the
        // Leaflet poster's fitBounds); a single point keeps the city zoom.
        if (points.length > 0) {
          const lats = points.map((p) => p[0]);
          const lngs = points.map((p) => p[1]);
          const min: [number, number] = [Math.min(...lats), Math.min(...lngs)];
          const max: [number, number] = [Math.max(...lats), Math.max(...lngs)];
          if (min[0] === max[0] && min[1] === max[1]) {
            map.current.setCenter(min, LANDING_ZOOM);
          } else {
            map.current.setBounds([min, max], { zoomMargin: 48 });
          }
        }
      })
      .catch((e) => {
        console.error("Yandex landing map failed, falling back to OSM", e);
        if (!cancelled) onErrorRef.current();
      });
    return () => {
      cancelled = true;
    };
  }, [jobs, lang, locale, negotiable]);

  useEffect(() => {
    return () => {
      map.current?.destroy();
      map.current = null;
    };
  }, []);

  // `relative z-0` isolates Yandex's internal pane z-indexes so the parent's
  // DOM overlays (chips at z-500/600) always stay above the map.
  return <div ref={el} className="relative z-0 h-full w-full" />;
}
