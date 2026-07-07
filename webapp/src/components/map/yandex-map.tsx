"use client";

import { useEffect, useRef } from "react";

import type { Job } from "@/lib/data/types";
import type { LatLng } from "@/lib/geo";
import { salaryPill, salaryText, schedulePatternLabel } from "@/lib/format";

import type { MapRatings } from "./jobs-map-inner";

/** JS-API key. A *JavaScript API* key (not the mobile MapKit key). */
const KEY = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY;
const TASHKENT: [number, number] = [41.3111, 69.2797];

/** Minimal typed surface of the bits of the Yandex JS API (v2.1) we touch. */
type YmapsObject = { events: { add: (t: string, f: () => void) => void } };
type YmapsMap = {
  geoObjects: { add: (o: YmapsObject) => void; removeAll: () => void };
  setCenter: (c: [number, number], zoom?: number) => void;
  destroy: () => void;
};
type YmapsApi = {
  ready: (cb: () => void) => void;
  Map: new (
    el: HTMLElement,
    state: Record<string, unknown>,
    opts?: Record<string, unknown>,
  ) => YmapsMap;
  Placemark: new (
    coords: [number, number],
    props: Record<string, unknown>,
    opts?: Record<string, unknown>,
  ) => YmapsObject;
  templateLayoutFactory: { createClass: (tpl: string) => unknown };
};

declare global {
  interface Window {
    ymaps?: YmapsApi;
  }
}

let loader: Promise<YmapsApi> | null = null;

/** Load the Yandex JS API once; reject (→ OSM fallback) on failure/timeout. */
function loadYmaps(lang: string): Promise<YmapsApi> {
  if (typeof window === "undefined") {
    return Promise.reject(new Error("no window"));
  }
  if (window.ymaps) return Promise.resolve(window.ymaps);
  if (!loader) {
    loader = new Promise<YmapsApi>((resolve, reject) => {
      const s = document.createElement("script");
      s.src = `https://api-maps.yandex.ru/2.1/?apikey=${KEY}&lang=${lang}`;
      s.async = true;
      s.onerror = () => reject(new Error("yandex script error"));
      s.onload = () => {
        if (window.ymaps) window.ymaps.ready(() => resolve(window.ymaps!));
        else reject(new Error("ymaps missing"));
      };
      document.head.appendChild(s);
      setTimeout(() => reject(new Error("yandex timeout")), 10_000);
    });
  }
  return loader;
}

type Located = Job & { lat: number; lng: number };

/** Balloon (popup) HTML for a job pin — mirrors the Leaflet PinCard. */
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
    <a href="/${locale}/jobs/${job.id}" style="display:block;font-weight:700;color:#0A0A0A">${job.title}</a>
    <div style="color:#666;font-size:13px">${job.companyName}${stars}</div>
    ${salary ? `<div style="font-weight:600;font-size:13px;margin-top:2px">${salary}</div>` : ""}
    ${meta ? `<div style="color:#666;font-size:12px">${meta}</div>` : ""}
    <a href="/${locale}/jobs/${job.id}/apply" style="display:inline-block;margin-top:8px;background:#C7FB00;color:#0A0A0A;border-radius:9999px;padding:6px 12px;font-size:13px;font-weight:600;text-decoration:none">${applyLabel}</a>
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
