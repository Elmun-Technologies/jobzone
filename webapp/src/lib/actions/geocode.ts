"use server";

// Server-side Yandex HTTP Geocoder. Uses YANDEX_GEOCODER_API_KEY (a *Geocoder
// API* key, distinct from the JS Maps key) — kept server-side so it's never
// exposed to the client. Powers the post-a-job location picker's two-way
// address↔map fill. Every failure degrades to null (best-effort).

export interface GeoAddress {
  city: string;
  address: string;
}

const GEOCODER_URL = "https://geocode-maps.yandex.ru/1.x/";

type Component = { kind?: string; name?: string };

function yLang(locale: string): string {
  return locale === "en" ? "en_US" : locale === "uz" ? "uz" : "ru_RU";
}

/** One geocode request → the first GeoObject, or null. */
async function queryGeocoder(
  geocode: string,
  locale: string,
): Promise<Record<string, unknown> | null> {
  const key = process.env.YANDEX_GEOCODER_API_KEY;
  if (!key) return null;
  const url = `${GEOCODER_URL}?apikey=${key}&format=json&results=1&lang=${yLang(
    locale,
  )}&geocode=${geocode}`;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
    if (!res.ok) return null;
    const data = (await res.json()) as {
      response?: {
        GeoObjectCollection?: {
          featureMember?: { GeoObject?: Record<string, unknown> }[];
        };
      };
    };
    return (
      data.response?.GeoObjectCollection?.featureMember?.[0]?.GeoObject ?? null
    );
  } catch {
    return null;
  }
}

/** Extract { city, address } from a GeoObject's address components. */
function toAddress(obj: Record<string, unknown>): GeoAddress {
  const meta = (
    obj.metaDataProperty as { GeocoderMetaData?: { Address?: unknown } }
  )?.GeocoderMetaData?.Address as
    { Components?: Component[]; formatted?: string } | undefined;
  const comps = meta?.Components ?? [];
  const find = (k: string) => comps.find((c) => c.kind === k)?.name ?? "";
  const city = find("locality") || find("province") || find("area") || "";
  const street = find("street");
  const house = find("house");
  const address =
    [street, house].filter(Boolean).join(" ") ||
    meta?.formatted ||
    (typeof obj.name === "string" ? obj.name : "") ||
    "";
  return { city, address };
}

/** Point → { city, address }. */
export async function reverseGeocode(
  lat: number,
  lng: number,
  locale = "ru",
): Promise<GeoAddress | null> {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  const obj = await queryGeocoder(`${lng},${lat}`, locale);
  return obj ? toAddress(obj) : null;
}

/** Address string → { lat, lng }. */
export async function forwardGeocode(
  q: string,
  locale = "ru",
): Promise<{ lat: number; lng: number } | null> {
  const s = q.trim();
  if (s.length < 3) return null;
  const obj = await queryGeocoder(encodeURIComponent(s), locale);
  const pos = (obj?.Point as { pos?: string } | undefined)?.pos;
  if (typeof pos !== "string") return null;
  const [lng, lat] = pos.split(" ").map(Number);
  return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null;
}
