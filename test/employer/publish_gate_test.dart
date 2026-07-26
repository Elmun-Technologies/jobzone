import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/domain/publish_gate.dart';

/// Truth table for the client half of the "first vacancy free, then pay per
/// listing" rule. It has to agree with `guard_job_publish()` (0066) in both
/// directions: too permissive and the employer meets a bare `payment_required`
/// error, too strict and they are charged for a publish the database would
/// have allowed for free.
void main() {
  group('isChargeableMarketEntry', () {
    test('saving a draft is never a market entry', () {
      expect(
        isChargeableMarketEntry(wantsToGoLive: false, isEdit: false),
        isFalse,
      );
      expect(
        isChargeableMarketEntry(
          wantsToGoLive: false,
          isEdit: true,
          currentStatus: 'draft',
        ),
        isFalse,
      );
    });

    test('posting a new vacancy is a market entry', () {
      expect(
        isChargeableMarketEntry(wantsToGoLive: true, isEdit: false),
        isTrue,
      );
    });

    test('publishing a draft from the edit screen is a market entry', () {
      // The bug this covers: `!_isEdit` exempted this path, so the update
      // wrote status='open' straight past the paywall and the DB guard threw.
      expect(
        isChargeableMarketEntry(
          wantsToGoLive: true,
          isEdit: true,
          currentStatus: 'draft',
        ),
        isTrue,
      );
    });

    test('a vacancy that has already been live re-opens for free', () {
      expect(
        isChargeableMarketEntry(
          wantsToGoLive: true,
          isEdit: true,
          firstPublishedAt: DateTime(2026, 3, 1),
          currentStatus: 'closed',
        ),
        isFalse,
      );
    });

    test('editing a live vacancy is not a market entry', () {
      // Also the fallback for a database that predates 0066, where
      // first_published_at reads as null on every row.
      expect(
        isChargeableMarketEntry(
          wantsToGoLive: true,
          isEdit: true,
          currentStatus: 'open',
        ),
        isFalse,
      );
    });

    test('duplicating a published vacancy charges for the copy', () {
      // "Use as template" passes the source job for prefill but creates a NEW
      // vacancy, so isEdit is false and the copy is its own market entry.
      expect(
        isChargeableMarketEntry(
          wantsToGoLive: true,
          isEdit: false,
          firstPublishedAt: DateTime(2026, 3, 1),
          currentStatus: 'open',
        ),
        isTrue,
      );
    });
  });
}
