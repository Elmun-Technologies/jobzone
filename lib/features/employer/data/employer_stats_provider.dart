import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/enums/enums.dart';
import '../domain/employer_stats.dart';
import 'applicants_repository.dart';
import 'employer_jobs_repository.dart';

/// Derives the dashboard metrics from the employer's jobs and applicants.
final employerStatsProvider = FutureProvider<EmployerStats>((ref) async {
  final jobs = await ref.read(employerJobsRepositoryProvider).myJobs();
  final applicants = await ref
      .read(applicantsRepositoryProvider)
      .allApplicants();

  int countWhere(ApplicationStatus s) =>
      applicants.where((a) => a.status == s).length;

  return EmployerStats(
    totalJobs: jobs.length,
    openJobs: jobs.where((j) => j.status == 'open').length,
    totalApplicants: applicants.length,
    newApplicants: countWhere(ApplicationStatus.submitted),
    interviews: countWhere(ApplicationStatus.interview),
    hired: countWhere(ApplicationStatus.hired),
  );
});
