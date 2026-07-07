// City-centroid fallback so every open job shows up on the map even when the
// employer never dropped an exact pin. Real jobs frequently have a `city` but
// null `lat/lng`; without this they silently vanish from the map (the invariant
// is "a posted job is visible everywhere immediately"). We plot such jobs at
// their city centre with a small deterministic jitter so same-city jobs fan out
// instead of stacking on one point.

import type { Job } from "@/lib/data/types";
import type { LatLng } from "@/lib/geo";

/** Centroids for Uzbekistan's cities + regional capitals (WGS84). */
const CENTROIDS: Record<string, LatLng> = {
  toshkent: { lat: 41.3111, lng: 69.2797 },
  samarqand: { lat: 39.6542, lng: 66.9597 },
  buxoro: { lat: 39.7747, lng: 64.4286 },
  andijon: { lat: 40.7821, lng: 72.3442 },
  namangan: { lat: 40.9983, lng: 71.6726 },
  fargona: { lat: 40.3894, lng: 71.7843 },
  nukus: { lat: 42.4531, lng: 59.6103 },
  qarshi: { lat: 38.86, lng: 65.7847 },
  termiz: { lat: 37.2242, lng: 67.2783 },
  jizzax: { lat: 40.1158, lng: 67.8422 },
  guliston: { lat: 40.4897, lng: 68.7842 },
  navoiy: { lat: 40.0844, lng: 65.3792 },
  urganch: { lat: 41.55, lng: 60.6333 },
  xiva: { lat: 41.3783, lng: 60.3639 },
  qoqon: { lat: 40.5286, lng: 70.9425 },
  margilon: { lat: 40.4711, lng: 71.7247 },
  chirchiq: { lat: 41.4689, lng: 69.5822 },
  angren: { lat: 41.0167, lng: 70.1436 },
  olmaliq: { lat: 40.8447, lng: 69.5981 },
  bekobod: { lat: 40.2206, lng: 69.2697 },
  zarafshon: { lat: 41.5725, lng: 64.2036 },
  shahrisabz: { lat: 39.0578, lng: 66.8306 },
  denov: { lat: 38.2678, lng: 67.8942 },
  kogon: { lat: 39.7222, lng: 64.5528 },
};

/** Common uz/ru/en spellings → canonical CENTROIDS key. */
const ALIASES: Record<string, string> = {
  tashkent: "toshkent",
  ташкент: "toshkent",
  samarkand: "samarqand",
  самарканд: "samarqand",
  bukhara: "buxoro",
  бухара: "buxoro",
  andijan: "andijon",
  андижан: "andijon",
  наманган: "namangan",
  fergana: "fargona",
  ferghana: "fargona",
  фергана: "fargona",
  karshi: "qarshi",
  qashqadaryo: "qarshi",
  карши: "qarshi",
  termez: "termiz",
  термез: "termiz",
  jizzakh: "jizzax",
  джизак: "jizzax",
  gulistan: "guliston",
  сырдарья: "guliston",
  navoi: "navoiy",
  наваи: "navoiy",
  navoiy: "navoiy",
  urgench: "urganch",
  ургенч: "urganch",
  khiva: "xiva",
  хива: "xiva",
  kokand: "qoqon",
  коканд: "qoqon",
  margilan: "margilon",
  маргилан: "margilon",
  chirchik: "chirchiq",
  чирчик: "chirchiq",
  ангрен: "angren",
  almalyk: "olmaliq",
  алмалык: "olmaliq",
  bekabad: "bekobod",
  zarafshan: "zarafshon",
  shakhrisabz: "shahrisabz",
  // Tashkent city districts + nearby Tashkent-region towns → Tashkent.
  chilonzor: "toshkent",
  чиланзар: "toshkent",
  yunusobod: "toshkent",
  юнусабад: "toshkent",
  mirzoulugbek: "toshkent",
  yakkasaroy: "toshkent",
  sergeli: "toshkent",
  uchtepa: "toshkent",
  shayxontohur: "toshkent",
  olmazor: "toshkent",
  bektemir: "toshkent",
  yashnobod: "toshkent",
  mirobod: "toshkent",
  yangihayot: "toshkent",
  nurafshon: "toshkent",
  yangiyol: "toshkent",
};

// Admin-marker words dropped so "Toshkent shahri" / "г. Ташкент" / "Chilonzor
// tumani" collapse to the bare place name (matched as whole words, so
// "Shahrisabz" is never mangled).
const ADMIN_WORDS = new Set([
  "shahri",
  "shahar",
  "shahridagi",
  "tumani",
  "tuman",
  "viloyati",
  "viloyat",
  "gorod",
  "город",
  "г",
  "область",
  "обл",
  "район",
  "rayon",
  "region",
]);

/** Lowercase, drop accents/apostrophes + admin-marker words, keep letters. */
function normalize(city: string): string {
  const cleaned = city
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "") // combining accents
    .replace(/['`ʻʼʹ‘’]/g, ""); // apostrophes (o' g')
  return cleaned
    .split(/[^a-zа-я]+/)
    .filter((w) => w && !ADMIN_WORDS.has(w))
    .join("");
}

/** Centroid for a city name (any common spelling), or null if unknown. */
export function cityLatLng(city: string | null | undefined): LatLng | null {
  if (!city) return null;
  const key = normalize(city);
  const canonical = ALIASES[key] ?? key;
  return CENTROIDS[canonical] ?? null;
}

/** Deterministic 32-bit hash of a string (FNV-1a) — stable jitter per job. */
function hash(s: string): number {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

/** ~±1.6 km deterministic offset so jobs sharing a city centroid fan out. */
function jitter(seed: string): { dLat: number; dLng: number } {
  const h = hash(seed);
  return {
    dLat: ((h % 1000) / 1000 - 0.5) * 0.03,
    dLng: (((h >>> 10) % 1000) / 1000 - 0.5) * 0.03,
  };
}

/**
 * The map coordinate for a job: its exact pin if set, else its city centroid
 * (jittered by id), else Tashkent. An open job is **never** dropped from the
 * map — the worst case (unknown/blank city) lands at Tashkent, most of the
 * market — so "a posted job is visible everywhere" always holds.
 */
export function jobLatLng(job: Job): LatLng {
  if (job.lat != null && job.lng != null) {
    return { lat: job.lat, lng: job.lng };
  }
  const centroid = cityLatLng(job.city) ?? CENTROIDS.toshkent;
  const { dLat, dLng } = jitter(job.id);
  return { lat: centroid.lat + dLat, lng: centroid.lng + dLng };
}
