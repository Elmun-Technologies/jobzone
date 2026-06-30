"use client";

import "leaflet/dist/leaflet.css";

import { useLocale } from "next-intl";
import { CircleMarker, MapContainer, Popup, TileLayer } from "react-leaflet";

import type { Job } from "@/lib/data/types";
import { salaryText } from "@/lib/format";

const TASHKENT: [number, number] = [41.3111, 69.2797];

export default function ExploreMapInner({ jobs }: { jobs: Job[] }) {
  const locale = useLocale();
  const located = jobs.filter(
    (j): j is Job & { lat: number; lng: number } =>
      j.lat != null && j.lng != null,
  );

  return (
    <MapContainer
      center={TASHKENT}
      zoom={6}
      scrollWheelZoom
      className="h-[70vh] w-full rounded-xl"
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      />
      {located.map((j) => {
        const salary = salaryText(j);
        return (
          <CircleMarker
            key={j.id}
            center={[j.lat, j.lng]}
            radius={10}
            pathOptions={{
              color: "#3A36DB",
              fillColor: "#3A36DB",
              fillOpacity: 0.85,
              weight: 2,
            }}
          >
            <Popup>
              <a
                href={`/${locale}/jobs/${j.id}`}
                className="font-semibold text-[#3A36DB]"
              >
                {j.title}
              </a>
              <div>{j.companyName}</div>
              {salary ? <div>{salary}</div> : null}
            </Popup>
          </CircleMarker>
        );
      })}
    </MapContainer>
  );
}
