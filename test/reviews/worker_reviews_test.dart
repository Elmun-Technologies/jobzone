import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/reviews/data/worker_reviews_repository.dart';
import 'package:jobzone/features/reviews/domain/worker_review.dart';

void main() {
  // No Supabase env in tests → the repository keeps reviews in memory.
  test('submit then reputation reflects the review (offline)', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final repo = c.read(workerReviewsRepositoryProvider);

    expect((await repo.reputation('w1')).hasReviews, isFalse);

    await repo.submit(
      const WorkerReview(workerId: 'w1', rating: 5, reliability: 4),
    );

    final rep = await repo.reputation('w1');
    expect(rep.reviewCount, 1);
    expect(rep.avgRating, 5);
    expect(rep.reliabilityScore, 92); // (5*0.6 + 4*0.4) * 20
  });
}
