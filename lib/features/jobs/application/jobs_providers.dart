import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/jobs_repository_impl.dart';
import '../domain/job.dart';
import 'bookmarks_controller.dart';

final suggestedJobsProvider = FutureProvider<List<Job>>(
  (ref) => ref.watch(jobsRepositoryProvider).suggested(),
);

final recentJobsProvider = FutureProvider<List<Job>>(
  (ref) => ref.watch(jobsRepositoryProvider).recent(),
);

final jobByIdProvider = FutureProvider.family<Job?, String>(
  (ref, id) => ref.watch(jobsRepositoryProvider).byId(id),
);

/// Jobs the user has bookmarked (re-resolves when the bookmark set changes).
final bookmarkedJobsProvider = FutureProvider<List<Job>>((ref) async {
  final ids = await ref.watch(bookmarksControllerProvider.future);
  return ref.watch(jobsRepositoryProvider).byIds(ids);
});

/// Open jobs posted by a given company (Company Details → Open Jobs tab).
final companyJobsProvider = FutureProvider.family<List<Job>, String>(
  (ref, companyId) => ref.watch(jobsRepositoryProvider).byCompany(companyId),
);
