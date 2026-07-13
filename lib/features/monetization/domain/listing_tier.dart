/// The per-listing visibility tiers an employer picks when posting a vacancy.
/// The first vacancy is free; from the 2nd onward the employer chooses one of
/// these (min 39,900). The choice sets both the price charged and the visual
/// treatment the listing gets everywhere (card + map), for the life of the
/// listing — it replaces the old separate TOP/featured boost packages.
///
/// Mirrors the web source of truth `webapp/src/lib/listing-tiers.ts`; the
/// numbers are guarded by `test/monetization/listing_tier_test.dart`. Tier
/// names/copy are localized in the ARB (`tier*`), so the domain only carries the
/// price and the nudge flag.
enum ListingTier { standard, brand, premium }

class ListingTierInfo {
  const ListingTierInfo({
    required this.tier,
    required this.priceUzs,
    this.featured = false,
  });

  final ListingTier tier;
  final int priceUzs;

  /// The nudge target — rendered with the "most popular" emphasis.
  final bool featured;

  bool get isPremium => tier == ListingTier.premium;
}

/// The three tiers, cheapest first. Keep in sync with `LISTING_TIERS` on web.
const kListingTiers = <ListingTierInfo>[
  ListingTierInfo(tier: ListingTier.standard, priceUzs: 39900),
  ListingTierInfo(tier: ListingTier.brand, priceUzs: 79900, featured: true),
  ListingTierInfo(tier: ListingTier.premium, priceUzs: 99900),
];
