import type { Job } from "@/lib/data/types";
import { jobLatLng } from "@/lib/uz-geo";

// Pin capacity for the landing showcase — must match SLOTS in landing-map.tsx.
// Kept here (isomorphic module) so the RSC page can pre-select the same set of
// jobs the client component will render and pre-format the result count.
export const LANDING_MAP_PIN_COUNT = 8;

// Uzbekistan's bounding box (WGS84, padded). The landing spot is a *country
// poster* framed on the pins' bounds, so a foreign posting (e.g. a Moscow
// "Foreign jobs" listing) would blow the frame out to a continent view — the
// exact "beso'naqay" the screenshot showed. The full /explore map still shows
// every job, foreign ones included; only this poster is geofenced.
const UZ_BOUNDS = { latMin: 37.0, latMax: 45.7, lngMin: 55.9, lngMax: 73.3 };

function inUzbekistan(job: Job): boolean {
  const { lat, lng } = jobLatLng(job);
  return (
    lat >= UZ_BOUNDS.latMin &&
    lat <= UZ_BOUNDS.latMax &&
    lng >= UZ_BOUNDS.lngMin &&
    lng <= UZ_BOUNDS.lngMax
  );
}

/** Trim the job list to what the landing map will actually pin: salaried jobs
 * located inside Uzbekistan, capped at LANDING_MAP_PIN_COUNT. */
export function pickLandingMapJobs(jobs: Job[]): Job[] {
  return jobs
    .filter((j) => j.salaryMin != null || j.salaryMax != null)
    .filter(inUzbekistan)
    .slice(0, LANDING_MAP_PIN_COUNT);
}
