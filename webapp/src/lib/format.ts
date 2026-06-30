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
