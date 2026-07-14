"use client";

import { useEffect, useRef } from "react";

import type { Job } from "@/lib/data/types";
import type { LatLng } from "@/lib/geo";
import { salaryPill } from "@/lib/format";
import { loadYmaps, type YmapsMap } from "@/lib/yandex-maps-loader";

import {
  pinLabel,
  pinShadow,
  SALARY_PIN_SHAPE,
  salaryPinMarkup,
} from "./pin-markup";
import { mapTier } from "./tier";

const TASHKENT: [number, number] = [41.3111, 69.2797];

type Located = Job & { lat: number; lng: number };

/**
 * Yandex Maps (JS API v2.1) renderer — the branded volt/ink salary pins on
 * Yandex tiles. Only mounted when a JS-API key is present; any load/init
 * failure calls `onError` so the parent falls back to the OSM map.
 *
 * Pins carry `data-job-id`, and hover (preview card) + click (job page) are
 * handled by the parent's DOM delegation (see job-pin-card.tsx) — no Yandex
 * balloons, so the experience is identical to the Leaflet fallback.
 */
export function YandexMap({
  jobs,
  loc,
  locale,
  youAreHere,
  negotiable,
  wheelZoom = true,
  onError,
}: {
  jobs: Located[];
  loc: LatLng | null;
  locale: string;
  youAreHere: string;
  /** Pill text for a job without a stated salary. */
  negotiable: string;
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
          // Zoom +/- buttons so the map is controllable without the wheel
          // (essential on the embedded landing map, where wheel-zoom is off to
          // avoid trapping page scroll). Placed top-right, below the count pill.
          map.current.controls.add("zoomControl", {
            position: { right: 12, top: 152 },
          });
        } else if (loc) {
          map.current.setCenter([loc.lat, loc.lng], 13);
        }

        // The mockup's volt price tag: the SALARY is the pin (details live in
        // the hover card). One layout class for every pin — per-pin text comes
        // in via properties, which Yandex's template substitution HTML-escapes.
        const PinLayout = ymaps.templateLayoutFactory.createClass(
          salaryPinMarkup({
            pill: "$[properties.pill]",
            jobId: "$[properties.jobId]",
            shadow: "$[properties.pinShadow]",
          }),
        );

        map.current.geoObjects.removeAll();

        // A volt price-tag placemark per job. `iconShape` gives the clusterer
        // the tag's bounds (without it, it drew a stray count badge over every
        // tag). Co-located / overlapping jobs collapse into one ink count
        // bubble (groupByCoordinates + minClusterSize) that expands on click;
        // a lone job keeps its clean volt tag.
        const placemarks = jobs.map((job) => {
          const tier = mapTier(job.boostKind);
          return new ymaps.Placemark(
            [job.lat, job.lng],
            {
              pill: pinLabel(salaryPill(job) ?? negotiable, tier),
              jobId: job.id,
              pinShadow: pinShadow(tier),
            },
            { iconLayout: PinLayout, iconShape: SALARY_PIN_SHAPE },
          );
        });
        if (ymaps.Clusterer) {
          const clusterer = new ymaps.Clusterer({
            preset: "islands#blackClusterIcons",
            groupByCoordinates: true,
            minClusterSize: 2,
            gridSize: 48,
            clusterDisableClickZoom: false,
          });
          clusterer.add(placemarks);
          map.current.geoObjects.add(clusterer);
        } else {
          for (const p of placemarks) map.current.geoObjects.add(p);
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
  }, [jobs, loc, lang, negotiable, youAreHere, wheelZoom]);

  useEffect(() => {
    return () => {
      map.current?.destroy();
      map.current = null;
    };
  }, []);

  return <div ref={el} className="relative z-0 h-full w-full" />;
}
