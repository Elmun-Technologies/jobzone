import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/data/mock_employer.dart';
import 'package:jobzone/features/monetization/data/monetization_repository.dart';
import 'package:jobzone/features/monetization/domain/promotion.dart';

void main() {
  group('MonetizationRepository (offline)', () {
    setUp(() => mockEmployer.resetJobsForTest());

    MonetizationRepository repo() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container.read(monetizationRepositoryProvider);
    }

    test('catalog exposes the seeded products + prices', () async {
      final products = await repo().products();
      expect(
        products.map((p) => p.code),
        containsAll([
          'start',
          'featured',
          'top_3',
          'top_7',
          'top_30',
          'ai_screening',
        ]),
      );
      expect(products.firstWhere((p) => p.code == 'top_3').priceUzs, 15000);
      expect(products.firstWhere((p) => p.code == 'start').isFree, isTrue);
      expect(
        products.firstWhere((p) => p.code == 'ai_screening').isComingSoon,
        isTrue,
      );
    });

    test(
      'buying a TOP package boosts the job and records a paid order',
      () async {
        final r = repo();
        expect(
          mockEmployer.jobs.firstWhere((j) => j.id == 'mock-3').isBoosted,
          isFalse,
        );

        final order = await r.purchase(jobId: 'mock-3', productCode: 'top_7');
        expect(order.isPaid, isTrue);
        expect(order.amountUzs, 35000);

        final job = mockEmployer.jobs.firstWhere((j) => j.id == 'mock-3');
        expect(job.isBoosted, isTrue);
        expect(job.boostKind, 'top');

        expect((await r.myOrders()).any((o) => o.id == order.id), isTrue);
      },
    );

    test('formatUzs groups thousands with a space', () {
      expect(formatUzs(15000), "15 000 so'm");
      expect(formatUzs(99000), "99 000 so'm");
    });
  });
}
