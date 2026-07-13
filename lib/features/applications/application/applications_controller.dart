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
    String? resumeId,
  }) async {
    await ref
        .read(applicationsRepositoryProvider)
        .apply(
          job: job,
          coverLetter: coverLetter,
          answers: answers,
          resumeId: resumeId,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> withdraw(String applicationId) async {
    await ref.read(applicationsRepositoryProvider).withdraw(applicationId);
    ref.invalidateSelf();
    await future;
  }
}

/// Whether the current user has already applied to [jobId] — drives the
/// job-details Apply button's disabled "Applied" state.
final hasAppliedProvider = Provider.family<bool, String>((ref, jobId) {
  final apps = ref.watch(applicationsControllerProvider).value;
  return apps?.any((a) => a.job.id == jobId) ?? false;
});

final applicationsControllerProvider =
    AsyncNotifierProvider<ApplicationsController, List<Application>>(
      ApplicationsController.new,
    );

/// Status timeline for a single application.
final statusHistoryProvider = FutureProvider.family<List<StatusEvent>, String>(
  (ref, id) => ref.read(applicationsRepositoryProvider).statusHistory(id),
);
