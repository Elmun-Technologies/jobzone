// Shared Yandex Maps JS API (v2.1) script loader. Used by both the read-only
// display map (components/map/yandex-map.tsx) and the location picker
// (components/map/yandex-location-picker.tsx) so only one <script> tag is
// ever injected regardless of which one mounts first.

const KEY = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY;

/** Minimal typed surface of the bits of the Yandex JS API (v2.1) we touch. */
export type YmapsEvent = { get: (k: string) => unknown };
export type YmapsGeoObject = {
  geometry: { getCoordinates: () => [number, number] } | null;
  getLocalities?: () => string[];
  getAdministrativeAreas?: () => string[];
  getThoroughfare?: () => string;
  getPremiseNumber?: () => string;
  getAddressLine?: () => string;
};
export type YmapsGeocodeResult = {
  geoObjects: { get: (i: number) => YmapsGeoObject | null };
};
export type YmapsObject = {
  events: { add: (t: string, f: (e: YmapsEvent) => void) => void };
  geometry: { getCoordinates: () => [number, number] };
};
export type YmapsMap = {
  geoObjects: {
    add: (o: YmapsObject) => void;
    remove: (o: YmapsObject) => void;
    removeAll: () => void;
  };
  events: { add: (t: string, f: (e: YmapsEvent) => void) => void };
  behaviors: { disable: (name: string) => void; enable: (name: string) => void };
  setCenter: (c: [number, number], zoom?: number) => void;
  destroy: () => void;
};
export type YmapsApi = {
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
  geocode: (
    request: string | [number, number],
    opts?: Record<string, unknown>,
  ) => Promise<YmapsGeocodeResult>;
  templateLayoutFactory: { createClass: (tpl: string) => unknown };
};

declare global {
  interface Window {
    ymaps?: YmapsApi;
  }
}

let loader: Promise<YmapsApi> | null = null;

/** Load the Yandex JS API once; reject (→ OSM fallback) on failure/timeout. */
export function loadYmaps(lang: string): Promise<YmapsApi> {
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

export const YANDEX_MAPS_KEY = KEY;
