"use client";

import "leaflet/dist/leaflet.css";

import L from "leaflet";
import { useTranslations } from "next-intl";
import { useEffect, useState } from "react";
import {
  MapContainer,
  Marker,
  TileLayer,
  useMap,
  useMapEvents,
} from "react-leaflet";

import { useUserLocation } from "@/lib/geo";
import { cityLatLng } from "@/lib/uz-geo";

import { YandexLocationPicker } from "./yandex-location-picker";

const TASHKENT: [number, number] = [41.3111, 69.2797];
const YANDEX_KEY = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY;

const pickIcon = L.divIcon({
  className: "",
  html: `<span style="display:block;width:18px;height:18px;border-radius:9999px;
    transform:translate(-50%,-50%);background:#C7FB00;border:3px solid #0A0A0A;
    box-shadow:0 0 0 4px rgba(199,251,0,.25)"></span>`,
  iconSize: [0, 0],
  iconAnchor: [0, 0],
});

function ClickCapture({
  onPick,
}: {
  onPick: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      onPick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

/** Recenters while no pin has been dropped yet (e.g. the employer typed a
 * recognized city) — stops once a pin exists so it never fights the user. */
function RecenterWhileUnset({
  to,
  active,
}: {
  to: [number, number];
  active: boolean;
}) {
  const map = useMap();
  useEffect(() => {
    if (active) map.setView(to, 13);
  }, [active, to, map]);
  return null;
}

/**
 * Click-to-drop-pin location picker for the post-a-job wizard's "Manzil"
 * step. Yandex when a JS-API key is set (falls back to Leaflet/OSM on any
 * load error), otherwise Leaflet/OSM directly — same engine split as the
 * read-only `<JobsMap>`.
 */
export default function LocationPickerInner({
  lat,
  lng,
  onChange,
  cityHint,
  locale,
}: {
  lat: number | null;
  lng: number | null;
  onChange: (v: { lat: number; lng: number } | null) => void;
  cityHint?: string | null;
  locale: string;
}) {
  const t = useTranslations("employer.post");
  const [yandexFailed, setYandexFailed] = useState(false);
  const { loc, status, request } = useUserLocation();
  const useYandex = !!YANDEX_KEY && !yandexFailed;

  const pin: [number, number] | null =
    lat != null && lng != null ? [lat, lng] : null;
  const hinted = cityHint ? cityLatLng(cityHint) : null;
  const center: [number, number] = pin ?? [
    hinted?.lat ?? TASHKENT[0],
    hinted?.lng ?? TASHKENT[1],
  ];

  function pick(la: number, ln: number) {
    onChange({ lat: la, lng: ln });
  }

  useEffect(() => {
    if (status === "granted" && loc) onChange({ lat: loc.lat, lng: loc.lng });
    // Fire only on a fresh geolocation grant, not on every parent re-render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status, loc]);

  return (
    <div>
      <div className="border-border relative h-56 overflow-hidden rounded-xl border">
        {useYandex ? (
          <YandexLocationPicker
            center={center}
            pin={pin}
            locale={locale}
            onPick={pick}
            onError={() => setYandexFailed(true)}
          />
        ) : (
          <MapContainer
            center={center}
            zoom={pin ? 15 : 13}
            scrollWheelZoom
            className="h-full w-full"
          >
            <TileLayer
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            />
            <ClickCapture onPick={pick} />
            <RecenterWhileUnset to={center} active={!pin} />
            {pin ? (
              <Marker
                position={pin}
                icon={pickIcon}
                draggable
                eventHandlers={{
                  dragend: (e) => {
                    const p = (e.target as L.Marker).getLatLng();
                    pick(p.lat, p.lng);
                  },
                }}
              />
            ) : null}
          </MapContainer>
        )}
      </div>
      <div className="mt-2 flex flex-wrap items-center gap-3 text-sm">
        <button
          type="button"
          onClick={request}
          className="text-primary font-medium hover:underline"
        >
          {status === "locating" ? t("locating") : `📍 ${t("useMyLocation")}`}
        </button>
        {pin ? (
          <button
            type="button"
            onClick={() => onChange(null)}
            className="text-muted-foreground font-medium hover:underline"
          >
            {t("removePin")}
          </button>
        ) : null}
        <span className="text-muted-foreground">
          {pin ? t("pinSet") : t("pinHint")}
        </span>
      </div>
    </div>
  );
}
