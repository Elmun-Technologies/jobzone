import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../jobs/domain/job.dart';
import '../data/applications_repository.dart';
import '../domain/application.dart';

/// The current user's applications (most recent first).
class ApplicationsController extends AsyncNotifier<List<Application>> {
  @override
  Future<List<Application>> build() =>
      ref.read(applicationsRepositoryProvider).myApplications();

  Future<void> apply({
    required Job job,
    String? coverLetter,
    Map<String, dynamic>? answers,
  }) async {
    await ref
        .read(applicationsRepositoryProvider)
        .apply(job: job, coverLetter: coverLetter, answers: answers);
    ref.invalidateSelf();
    await future;
  }
}

final applicationsControllerProvider =
    AsyncNotifierProvider<ApplicationsController, List<Application>>(
      ApplicationsController.new,
    );

/// Status timeline for a single application.
final statusHistoryProvider = FutureProvider.family<List<StatusEvent>, String>(
  (ref, id) => ref.read(applicationsRepositoryProvider).statusHistory(id),
);
