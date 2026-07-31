// The per-listing visibility tiers an employer picks when posting a vacancy.
// The first vacancy is always free; from the 2nd onward the employer chooses
// one of these (min 39,900). The choice sets both the price charged and the
// visual treatment the listing gets everywhere (card + map), for the life of
// the listing — it replaces the old separate TOP/featured boost packages.
//
// This is the marketing source of truth (the /pricing page). The mobile app
// mirrors these values in
// `lib/features/monetization/domain/listing_tier.dart`; the post-time picker
// and the `promotion_products` catalog (PR2) reuse the same three prices.

export type ListingTierCode = "standard" | "brand" | "premium";

export interface ListingTier {
  code: ListingTierCode;
  priceUzs: number;
  /** The nudge target — rendered with the "most popular" emphasis. */
  featured?: boolean;
}

export const LISTING_TIERS: ListingTier[] = [
  { code: "standard", priceUzs: 39_900 },
  { code: "brand", priceUzs: 79_900, featured: true },
  { code: "premium", priceUzs: 99_900 },
];

/**
 * How prominent a live listing is. Mirrors `jobs.boost_kind`, where a free or
 * Standart listing carries no tier at all — Standart is a paid listing, not a
 * visual treatment, so it ranks with "none".
 */
export function tierRank(tier: string | null | undefined): number {
  return tier === "premium" ? 2 : tier === "brand" ? 1 : 0;
}

/**
 * The tiers an already-live listing can still be upgraded to — strictly above
 * what it has. Keep in step with `create_listing_order`'s `not_an_upgrade`
 * guard (0075), which re-checks this server-side: the employer must never be
 * able to pay again for visibility the listing already has.
 */
export function upgradeTiersFor(
  currentTier: string | null | undefined,
): ListingTier[] {
  return LISTING_TIERS.filter(
    (tier) => tierRank(tier.code) > tierRank(currentTier),
  );
}
