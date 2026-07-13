// The per-listing visibility tiers an employer picks when posting a vacancy.
// The first vacancy is always free; from the 2nd onward the employer chooses
// one of these (min 39,900). The choice sets both the price charged and the
// visual treatment the listing gets everywhere (card + map), for the life of
// the listing — it replaces the old separate TOP/featured boost packages.
//
// This is the marketing source of truth (the /pricing page and the /about
// landing section). The mobile app mirrors these values in
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
