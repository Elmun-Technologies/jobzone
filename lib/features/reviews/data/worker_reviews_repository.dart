import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/worker_review.dart';

/// Reads + writes employer→worker reviews and the derived reputation. Offline
/// keeps submitted reviews in memory and computes the same reliability blend as
/// the `worker_reliability_summary` view.
class WorkerReviewsRepository {
  WorkerReviewsRepository(this._ref);

  final Ref _ref;

  bool get _live => Env.hasSupabase;

  Future<WorkerReputation> reputation(String workerId) async {
    if (!_live) return _reputationFrom(_offline[workerId] ?? const []);
    final row = await _ref
        .read(supabaseClientProvider)
        .from('worker_reliability_summary')
        .select()
        .eq('worker_id', workerId)
        .maybeSingle();
    return row == null
        ? const WorkerReputation()
        : WorkerReputation.fromMap(row);
  }

  /// Upserts the author's review of a worker for a job (one per tuple).
  Future<void> submit(WorkerReview review) async {
    if (!_live) {
      final list = _offline.putIfAbsent(review.workerId, () => []);
      list.insert(
        0,
        WorkerReview(
          id: 'wrev${_seq++}',
          workerId: review.workerId,
          rating: review.rating,
          reliability: review.reliability,
          body: review.body,
          jobId: review.jobId,
          authorName: 'You',
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    final client = _ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    await client
        .from('worker_reviews')
        .upsert(review.toInsert(uid), onConflict: 'worker_id,author_id,job_id');
  }

  WorkerReputation _reputationFrom(List<WorkerReview> list) {
    if (list.isEmpty) return const WorkerReputation();
    final n = list.length;
    final avgRating = list.fold<int>(0, (s, r) => s + r.rating) / n;
    final rel = list
        .where((r) => r.reliability != null)
        .map((r) => r.reliability!)
        .toList();
    final avgRel = rel.isEmpty
        ? avgRating
        : rel.reduce((a, b) => a + b) / rel.length;
    return WorkerReputation(
      avgRating: double.parse(avgRating.toStringAsFixed(2)),
      avgReliability: double.parse(avgRel.toStringAsFixed(2)),
      reviewCount: n,
      reliabilityScore: ((avgRating * 0.6 + avgRel * 0.4) * 20).round(),
    );
  }
}

final workerReviewsRepositoryProvider = Provider<WorkerReviewsRepository>(
  (ref) => WorkerReviewsRepository(ref),
);

final workerReputationProvider =
    FutureProvider.family<WorkerReputation, String>(
      (ref, workerId) =>
          ref.read(workerReviewsRepositoryProvider).reputation(workerId),
    );

int _seq = 1;
final _offline = <String, List<WorkerReview>>{};
