import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/review.dart';

/// Reads + writes company reviews. Offline mode keeps submitted reviews in an
/// in-memory list keyed by company so the Reviews tab reflects new entries.
class ReviewsRepository {
  ReviewsRepository(this._ref);

  final Ref _ref;

  Future<List<CompanyReview>> forCompany(String companyId) async {
    if (!Env.hasSupabase) {
      return List.unmodifiable(_offline[companyId] ?? const []);
    }
    final rows = await _ref
        .read(supabaseClientProvider)
        .from('company_reviews')
        .select('*, author:profiles_public(full_name)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => CompanyReview.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Upserts the author's review (one per company). Conflict target matches the
  /// `unique (company_id, author_id)` constraint.
  Future<void> submit(CompanyReview review) async {
    if (!Env.hasSupabase) {
      final list = _offline.putIfAbsent(review.companyId, () => []);
      list.insert(
        0,
        CompanyReview(
          id: 'rev${_seq++}',
          companyId: review.companyId,
          rating: review.rating,
          title: review.title,
          body: review.body,
          pros: review.pros,
          cons: review.cons,
          isCurrentEmployee: review.isCurrentEmployee,
          jobTitle: review.jobTitle,
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
        .from('company_reviews')
        .upsert(review.toInsert(uid), onConflict: 'company_id,author_id');
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref),
);

/// Reviews for a company, used by the Reviews tab.
final companyReviewsProvider =
    FutureProvider.family<List<CompanyReview>, String>(
      (ref, companyId) =>
          ref.read(reviewsRepositoryProvider).forCompany(companyId),
    );

int _seq = 1;
final _offline = <String, List<CompanyReview>>{};
