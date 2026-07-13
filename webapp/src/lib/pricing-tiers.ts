// The employer plan tiers — priced by how many *active* (open) vacancies a
// company runs at once, not per-post. The first vacancy is always free; beyond
// that it's a flat monthly volume tier. This is the single source of truth for
// the marketing pricing page (`/pricing`) and the landing pitch (`/about`
// pricing section), and — once wired — the plan-capacity gate at publish time.
// The mobile app mirrors these exact values in
// `lib/features/monetization/domain/vacancy_plan.dart` (a parity test guards
// the numbers). Prices in UZS; `maxJobs: null` means unlimited (the "50+" tier).
// Tier names are kept as English brand words in every locale (Free / Standard /
// Highlight / Business), matching the existing `landing.pricing.*` catalog.

export type PlanTierCode = "free" | "standard" | "highlight" | "business";

export interface PlanTier {
  code: PlanTierCode;
  /** Inclusive upper bound of active vacancies; null = unlimited. */
  maxJobs: number | null;
  priceUzs: number;
  /** The tier we highlight as the everyday sweet spot. */
  featured?: boolean;
}

export const PLAN_TIERS: PlanTier[] = [
  { code: "free", maxJobs: 1, priceUzs: 0 },
  { code: "standard", maxJobs: 10, priceUzs: 99_000 },
  { code: "highlight", maxJobs: 50, priceUzs: 199_000, featured: true },
  { code: "business", maxJobs: null, priceUzs: 499_000 },
];

/** The tier that covers `activeJobs` open vacancies (the cheapest whose cap
 * fits). Used by the capacity gate and to show "your plan" on the pricing page. */
export function tierForActiveJobs(activeJobs: number): PlanTier {
  return (
    PLAN_TIERS.find((t) => t.maxJobs !== null && activeJobs <= t.maxJobs) ??
    PLAN_TIERS[PLAN_TIERS.length - 1]
  );
}
