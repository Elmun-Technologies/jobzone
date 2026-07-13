import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/monetization/domain/listing_tier.dart';

void main() {
  group('listing tiers', () {
    test('three tiers at the agreed prices, cheapest first', () {
      expect(kListingTiers.map((t) => (t.tier, t.priceUzs)).toList(), [
        (ListingTier.standard, 39900),
        (ListingTier.brand, 79900),
        (ListingTier.premium, 99900),
      ]);
    });

    test('exactly one featured (nudge) tier — brand', () {
      final featured = kListingTiers.where((t) => t.featured).toList();
      expect(featured.length, 1);
      expect(featured.single.tier, ListingTier.brand);
    });
  });
}
