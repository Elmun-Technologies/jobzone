"use client";

import { useEffect, useRef } from "react";

import {
  loadYmaps,
  type YmapsApi,
  type YmapsMap,
  type YmapsObject,
} from "@/lib/yandex-maps-loader";

export interface ResolvedAddress {
  city: string;
  address: string;
}

/** Reverse-geocode a point → { city, address }, defensively (any failure → null). */
async function reverseGeocode(
  ymaps: YmapsApi,
  coords: [number, number],
): Promise<ResolvedAddress | null> {
  try {
    const res = await ymaps.geocode(coords, { results: 1 });
    const obj = res.geoObjects.get(0);
    if (!obj) return null;
    const city =
      obj.getLocalities?.()?.[0] || obj.getAdministrativeAreas?.()?.[0] || "";
    const street = obj.getThoroughfare?.() || "";
    const house = obj.getPremiseNumber?.() || "";
    const address =
      [street, house].filter(Boolean).join(" ") || obj.getAddressLine?.() || "";
    return { city, address };
  } catch {
    return null;
  }
}

/** Forward-geocode an address string → coords, defensively (any failure → null). */
async function forwardGeocode(
  ymaps: YmapsApi,
  query: string,
): Promise<[number, number] | null> {
  try {
    const res = await ymaps.geocode(query, { results: 1 });
    const obj = res.geoObjects.get(0);
    const coords = obj?.geometry?.getCoordinates();
    return coords ?? null;
  } catch {
    return null;
  }
}

/**
 * Yandex Maps (JS API v2.1) click-to-drop-pin picker for the post-a-job
 * wizard's location step. The marker is driven by the `pin` prop (so a click,
 * a "use my location" tap, or a typed address all render it consistently);
 * picking reverse-geocodes into the address fields, and typing an address
 * forward-geocodes onto the map. Any load/init failure calls `onError` so the
 * parent falls back to the Leaflet/OSM picker; geocoding is best-effort.
 */
export function YandexLocationPicker({
  center,
  pin,
  addressQuery,
  locale,
  onPick,
  onResolveAddress,
  onError,
}: {
  center: [number, number];
  pin: [number, number] | null;
  addressQuery?: string;
  locale: string;
  onPick: (lat: number, lng: number) => void;
  onResolveAddress?: (a: ResolvedAddress) => void;
  onError: () => void;
}) {
  const el = useRef<HTMLDivElement>(null);
  const map = useRef<YmapsMap | null>(null);
  const api = useRef<YmapsApi | null>(null);
  const placemark = useRef<YmapsObject | null>(null);
  const pinRef = useRef(pin);
  const onPickRef = useRef(onPick);
  const onResolveRef = useRef(onResolveAddress);
  const onErrorRef = useRef(onError);
  // Skip forward-geocoding the address change that our own reverse-geocode
  // just produced, so pick → fill → type doesn't loop.
  const suppressForward = useRef(false);
  // Skip reverse-geocoding a pin that forward-geocoding just placed, so
  // type → pin → fill → type doesn't loop the other way.
  const fromForward = useRef(false);
  const lastQuery = useRef<string>("");
  useEffect(() => {
    pinRef.current = pin;
  }, [pin]);
  useEffect(() => {
    onPickRef.current = onPick;
  }, [onPick]);
  useEffect(() => {
    onResolveRef.current = onResolveAddress;
  }, [onResolveAddress]);
  useEffect(() => {
    onErrorRef.current = onError;
  }, [onError]);
  const lang = locale === "en" ? "en_US" : "ru_RU";

  /** Create/move/remove the single pin marker to match a coordinate. */
  function syncMarker(coords: [number, number] | null) {
    const m = map.current;
    const ymaps = api.current;
    if (!m || !ymaps) return;
    if (placemark.current) {
      m.geoObjects.remove(placemark.current);
      placemark.current = null;
    }
    if (!coords) return;
    // A branded volt/ink teardrop instead of Yandex's default red preset.
    const Layout = ymaps.templateLayoutFactory.createClass(
      `<div style="position:relative;transform:translate(-50%,-100%)">
        <div style="width:26px;height:26px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);
          background:#C7FB00;border:2px solid #0A0A0A;box-shadow:0 2px 6px rgba(0,0,0,.3)"></div>
        <div style="position:absolute;top:7px;left:7px;width:10px;height:10px;border-radius:9999px;background:#0A0A0A"></div>
      </div>`,
    );
    const mark = new ymaps.Placemark(
      coords,
      {},
      {
        iconLayout: Layout,
        iconShape: {
          type: "Circle",
          coordinates: [0, -13],
          radius: 14,
        },
        draggable: true,
      },
    );
    mark.events.add("dragend", () => {
      const c = mark.geometry.getCoordinates();
      onPickRef.current(c[0], c[1]);
    });
    m.geoObjects.add(mark);
    placemark.current = mark;
  }

  /** Reverse-geocode a picked point and push it up into the address fields. */
  async function resolve(coords: [number, number]) {
    const ymaps = api.current;
    if (!ymaps || !onResolveRef.current) return;
    const a = await reverseGeocode(ymaps, coords);
    if (a && (a.city || a.address)) {
      suppressForward.current = true;
      onResolveRef.current(a);
    }
  }

  // Create the map once; pin/query changes are handled by the effects below.
  useEffect(() => {
    let cancelled = false;
    loadYmaps(lang)
      .then((ymaps) => {
        if (cancelled || !el.current || map.current) return;
        api.current = ymaps;
        const m = new ymaps.Map(
          el.current,
          {
            center: pinRef.current ?? center,
            zoom: pinRef.current ? 15 : 13,
            controls: ["zoomControl", "geolocationControl"],
          },
          { suppressMapOpenBlock: true },
        );
        map.current = m;
        m.events.add("click", (e) => {
          const coords = e.get("coords") as [number, number];
          onPickRef.current(coords[0], coords[1]);
        });
        if (pinRef.current) syncMarker(pinRef.current);
      })
      .catch((e) => {
        console.error("Yandex location picker failed, falling back to OSM", e);
        if (!cancelled) onErrorRef.current();
      });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lang]);

  // Marker follows the pin prop; recenter, and reverse-geocode the point into
  // the address fields — unless forward-geocoding is what placed it.
  useEffect(() => {
    syncMarker(pin);
    if (pin) {
      map.current?.setCenter(pin, 15);
      if (fromForward.current) {
        fromForward.current = false;
      } else {
        void resolve(pin);
      }
    }
  }, [pin]);

  // Recenter on the city hint while no pin has been dropped yet.
  useEffect(() => {
    if (!pin) map.current?.setCenter(center, 13);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [center]);

  // Typed address → forward-geocode → drop the pin there (debounced).
  useEffect(() => {
    const q = (addressQuery ?? "").trim();
    if (q === lastQuery.current) return;
    lastQuery.current = q;
    if (suppressForward.current) {
      suppressForward.current = false;
      return;
    }
    if (q.length < 4) return;
    const t = setTimeout(async () => {
      const ymaps = api.current;
      if (!ymaps) return;
      const coords = await forwardGeocode(ymaps, q);
      if (coords) {
        fromForward.current = true;
        onPickRef.current(coords[0], coords[1]);
      }
    }, 900);
    return () => clearTimeout(t);
  }, [addressQuery]);

  useEffect(() => {
    return () => {
      map.current?.destroy();
      map.current = null;
    };
  }, []);

  return <div ref={el} className="h-full w-full" />;
}
