import type { Job } from "@/lib/data/types";

// Pin capacity for the landing showcase — must match SLOTS in landing-map.tsx.
// Kept here (isomorphic module) so the RSC page can pre-select the same set of
// jobs the client component will render and pre-format the result count.
export const LANDING_MAP_PIN_COUNT = 8;

/** Trim the job list to what the landing map will actually pin: those with
 * a stated salary, capped at LANDING_MAP_PIN_COUNT. */
export function pickLandingMapJobs(jobs: Job[]): Job[] {
  return jobs
    .filter((j) => j.salaryMin != null || j.salaryMax != null)
    .slice(0, LANDING_MAP_PIN_COUNT);
}
