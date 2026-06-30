import type { Job } from "@/lib/data/types";

/** Groups digits with regular spaces: 2500000 -> "2 500 000". */
function groupDigits(n: number): string {
  return Math.round(n)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

function currencyLabel(currency: string): string {
  switch (currency.toUpperCase()) {
    case "UZS":
      return "so'm";
    case "USD":
      return "$";
    default:
      return currency;
  }
}

/**
 * Human salary string, e.g. "2 500 000 - 4 000 000 so'm" or "$2 500+".
 * Returns null when no salary is set (caller shows "Negotiable").
 */
export function salaryText(job: Job): string | null {
  const { salaryMin: min, salaryMax: max, currency } = job;
  if (min == null && max == null) return null;
  const cur = currencyLabel(currency);
  const isUsd = currency.toUpperCase() === "USD";
  const fmt = (n: number) =>
    isUsd ? `${cur}${groupDigits(n)}` : groupDigits(n);
  let amount: string;
  if (min != null && max != null) amount = `${fmt(min)} - ${fmt(max)}`;
  else if (min != null) amount = `${fmt(min)}+`;
  else amount = `${fmt(max!)}`;
  return isUsd ? amount : `${amount} ${cur}`;
}

/** ISO date -> "20.06.2026" (stable across server/client, locale-independent). */
export function formatDate(iso: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const dd = String(d.getUTCDate()).padStart(2, "0");
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${d.getUTCFullYear()}`;
}

/** City + country, e.g. "Tashkent, UZ". */
export function locationText(job: Job): string {
  return [job.city, job.country].filter(Boolean).join(", ");
}

// Uzbekistan is a fixed UTC+5 offset with no DST, so formatting against it is
// deterministic on both server and client (avoids hydration mismatches that a
// runtime-local timezone would cause).
const TASHKENT_OFFSET_MS = 5 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
const FRESH_MS = 2 * 60 * 60 * 1000;

/** "HH:mm" wall-clock in Tashkent (UTC+5). Deterministic across environments. */
export function tashkentClock(iso: string | null): string {
  if (!iso) return "";
  const t = Date.parse(iso);
  if (Number.isNaN(t)) return "";
  const d = new Date(t + TASHKENT_OFFSET_MS);
  const hh = String(d.getUTCHours()).padStart(2, "0");
  const mm = String(d.getUTCMinutes()).padStart(2, "0");
  return `${hh}:${mm}`;
}

/** Tashkent calendar-day index (whole days since epoch in UTC+5). */
function tashkentDay(ms: number): number {
  return Math.floor((ms + TASHKENT_OFFSET_MS) / DAY_MS);
}

export interface PostedInfo {
  /** Posted within the last 2 hours → eligible for a "just posted" badge. */
  fresh: boolean;
  /** Calendar days ago in Tashkent time: 0 today, 1 yesterday, n older. */
  dayOffset: number;
  /** "HH:mm" wall-clock the job was posted, Tashkent time. */
  clock: string;
}

/**
 * Freshness descriptor for a posting time, relative to [nowMs]. The caller
 * turns this into localized copy ("Just posted" / "Today 18:29" / "5d ago").
 * All arithmetic is epoch- or fixed-offset-based so it is hydration-safe.
 */
export function postedInfo(
  iso: string | null,
  nowMs: number,
): PostedInfo | null {
  if (!iso) return null;
  const t = Date.parse(iso);
  if (Number.isNaN(t)) return null;
  const age = nowMs - t;
  return {
    fresh: age >= 0 && age < FRESH_MS,
    dayOffset: Math.max(0, tashkentDay(nowMs) - tashkentDay(t)),
    clock: tashkentClock(iso),
  };
}

/** Groups an integer with regular spaces for display: 8913 -> "8 913". */
export function groupNumber(n: number): string {
  return Math.round(n)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}
