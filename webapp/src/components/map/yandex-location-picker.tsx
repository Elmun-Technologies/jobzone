"use client";

import { useEffect, useRef } from "react";

import {
  loadYmaps,
  type YmapsApi,
  type YmapsMap,
  type YmapsObject,
} from "@/lib/yandex-maps-loader";

/**
 * Yandex Maps (JS API v2.1) click-to-drop-pin picker for the post-a-job
 * wizard's location step. Mirrors the display map's engine split — mounted
 * only when a JS-API key is present; any load/init failure calls `onError`
 * so the parent falls back to the Leaflet/OSM picker.
 */
export function YandexLocationPicker({
  center,
  pin,
  locale,
  onPick,
  onError,
}: {
  center: [number, number];
  pin: [number, number] | null;
  locale: string;
  onPick: (lat: number, lng: number) => void;
  onError: () => void;
}) {
  const el = useRef<HTMLDivElement>(null);
  const map = useRef<YmapsMap | null>(null);
  const placemark = useRef<YmapsObject | null>(null);
  const pinRef = useRef(pin);
  const onPickRef = useRef(onPick);
  const onErrorRef = useRef(onError);
  useEffect(() => {
    pinRef.current = pin;
  }, [pin]);
  useEffect(() => {
    onPickRef.current = onPick;
  }, [onPick]);
  useEffect(() => {
    onErrorRef.current = onError;
  }, [onError]);
  const lang = locale === "en" ? "en_US" : "ru_RU";

  function placeAt(ymaps: YmapsApi, m: YmapsMap, coords: [number, number]) {
    if (placemark.current) {
      m.geoObjects.remove(placemark.current);
    }
    placemark.current = new ymaps.Placemark(
      coords,
      {},
      { preset: "islands#icon", iconColor: "#C7FB00", draggable: true },
    );
    placemark.current.events.add("dragend", () => {
      const [lat, lng] = placemark.current!.geometry.getCoordinates();
      onPickRef.current(lat, lng);
    });
    m.geoObjects.add(placemark.current);
  }

  // Create the map once; the picked point and re-centering are handled by
  // the effects below without recreating it.
  useEffect(() => {
    let cancelled = false;
    loadYmaps(lang)
      .then((ymaps) => {
        if (cancelled || !el.current || map.current) return;
        const m = new ymaps.Map(
          el.current,
          {
            center: pinRef.current ?? center,
            zoom: 13,
            controls: ["zoomControl"],
          },
          { suppressMapOpenBlock: true },
        );
        map.current = m;
        m.events.add("click", (e) => {
          const coords = e.get("coords") as [number, number];
          placeAt(ymaps, m, coords);
          onPickRef.current(coords[0], coords[1]);
        });
        if (pinRef.current) placeAt(ymaps, m, pinRef.current);
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

  // External "remove pin" clears the placemark; a newly-picked pin recenters.
  useEffect(() => {
    const m = map.current;
    if (!m) return;
    if (pin) {
      m.setCenter(pin, 15);
    } else if (placemark.current) {
      m.geoObjects.remove(placemark.current);
      placemark.current = null;
    }
  }, [pin]);

  // Recenter on the city hint while no pin has been dropped yet.
  useEffect(() => {
    if (!pin) map.current?.setCenter(center, 13);
  }, [center, pin]);

  useEffect(() => {
    return () => {
      map.current?.destroy();
      map.current = null;
    };
  }, []);

  return <div ref={el} className="h-full w-full" />;
}
