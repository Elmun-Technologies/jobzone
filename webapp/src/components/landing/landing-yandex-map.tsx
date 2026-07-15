"use client";

import { useLocale } from "next-intl";
import { useEffect, useRef } from "react";

import type { Job } from "@/lib/data/types";
import { salaryPill } from "@/lib/format";
import { jobLatLng } from "@/lib/uz-geo";
import { loadYmaps, type YmapsMap } from "@/lib/yandex-maps-loader";

import type { PinHoverApi } from "../map/job-pin-card";
import {
  pinLabel,
  pinShadow,
  SALARY_PIN_SHAPE,
  salaryPinMarkup,
} from "../map/pin-markup";
import { mapTier } from "../map/tier";

// Tashkent — fallback framing when no pin resolves to a point.
const TASHKENT: [number, number] = [41.3111, 69.2797];
const LANDING_ZOOM = 12;

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
  onPinClick,
  hoverApi,
  onError,
}: {
  /** Already trimmed by pickLandingMapJobs on the server. */
  jobs: Job[];
  /** Pill text for a job without a stated salary. */
  negotiable: string;
  /** Navigate to a job — Yandex captures clicks in its own event pane. */
  onPinClick: (jobId: string) => void;
  /** Drive the shared hover card from the placemarks' ymaps events. */
  hoverApi: PinHoverApi;
  onError: () => void;
}) {
  const locale = useLocale();
  const el = useRef<HTMLDivElement>(null);
  const map = useRef<YmapsMap | null>(null);
  // Keep the latest callbacks without making them effect dependencies (the
  // parent passes fresh closures each render).
  const onErrorRef = useRef(onError);
  const onPinClickRef = useRef(onPinClick);
  const hoverApiRef = useRef(hoverApi);
  useEffect(() => {
    onErrorRef.current = onError;
    onPinClickRef.current = onPinClick;
    hoverApiRef.current = hoverApi;
  }, [onError, onPinClick, hoverApi]);
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

        // The shared volt salary bubble (see ../map/pin-markup.ts). Per-pin
        // text arrives via properties, which Yandex's template substitution
        // HTML-escapes. Hover (preview card) and click (job page) come through
        // each placemark's ymaps events (below) into the parent's hover API.
        const PillLayout = ymaps.templateLayoutFactory.createClass(
          salaryPinMarkup({
            pill: "$[properties.pill]",
            jobId: "$[properties.jobId]",
            shadow: "$[properties.pinShadow]",
          }),
        );

        map.current.geoObjects.removeAll();
        const points: [number, number][] = [];
        for (const job of jobs) {
          const pos = jobLatLng(job);
          points.push([pos.lat, pos.lng]);
          const tier = mapTier(job.boostKind);
          const pm = new ymaps.Placemark(
            [pos.lat, pos.lng],
            {
              pill: pinLabel(salaryPill(job) ?? negotiable, tier),
              jobId: job.id,
              pinShadow: pinShadow(tier),
            },
            { iconLayout: PillLayout, iconShape: SALARY_PIN_SHAPE },
          );
          // Hover/click come through ymaps' event pane, not bubbled DOM.
          pm.events.add("mouseenter", () =>
            hoverApiRef.current.openByJobId(job.id),
          );
          pm.events.add("mouseleave", () =>
            hoverApiRef.current.scheduleClose(),
          );
          pm.events.add("click", () => onPinClickRef.current(job.id));
          map.current.geoObjects.add(pm);
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
  }, [jobs, lang, negotiable]);

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
