import type { Job } from "@/lib/data/types";

// Landing-page "quick facts" — cheap aggregates computed from the same
// job set the page already loads for the ItemList schema. Kept in one
// module so the numbers a user sees (visible), the numbers GEO models
// quote (they read the visible copy first), and any future JSON-LD
// aggregate ratings never drift apart.

export interface SalaryRange {
  /** Lower end of the range (UZS), rounded to the nearest 1 000 000. */
  low: number;
  /** Upper end of the range (UZS), rounded to the nearest 1 000 000. */
  high: number;
  /** How many of the input jobs carried salary data. */
  n: number;
}

/**
 * Coarse UZS salary range across [jobs] — the 25th → 75th percentile
 * band using the max stated salary of each job. USD-quoted postings and
 * postings marked "negotiable" (no salary) are excluded so a single
 * outlier can't skew the number. Returns null when fewer than three
 * eligible postings — the range would be noise.
 */
export function uzsSalaryRange(jobs: Job[]): SalaryRange | null {
  const values: number[] = [];
  for (const j of jobs) {
    if (j.currency.toUpperCase() !== "UZS") continue;
    const top = j.salaryMax ?? j.salaryMin;
    if (top == null || top <= 0) continue;
    values.push(top);
  }
  if (values.length < 3) return null;
  values.sort((a, b) => a - b);
  const pick = (p: number) =>
    values[Math.min(values.length - 1, Math.floor(p * values.length))];
  const low = pick(0.25);
  const high = pick(0.75);
  // Round to the nearest 1M so the "3,4 – 5,7 mln so'm" fluctuation on
  // every render stays inside the same tag.
  const round = (n: number) => Math.round(n / 100_000) * 100_000;
  return { low: round(low), high: round(high), n: values.length };
}

/**
 * Most recent postedAt among [jobs], as an ISO string, or null if no
 * posting has one. Used for the visible "Updated on …" note and for
 * sitemap lastmod on landing pages.
 */
export function latestPostedAt(jobs: Job[]): string | null {
  let latest: number | null = null;
  for (const j of jobs) {
    if (!j.postedAt) continue;
    const t = Date.parse(j.postedAt);
    if (Number.isNaN(t)) continue;
    if (latest == null || t > latest) latest = t;
  }
  return latest == null ? null : new Date(latest).toISOString();
}
