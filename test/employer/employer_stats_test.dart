import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/data/employer_stats_provider.dart';
import 'package:jobzone/features/employer/data/mock_employer.dart';

void main() {
  // No Supabase env in tests → stats are derived from the seeded offline stores.
  test('employerStatsProvider aggregates jobs and applicants', () async {
    mockEmployer.resetJobsForTest();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final stats = await container.read(employerStatsProvider.future);

    // Seeded c-acme jobs are all open; seeded applicants span several stages.
    expect(stats.totalJobs, greaterThan(0));
    expect(stats.openJobs, stats.totalJobs);
    expect(stats.totalApplicants, greaterThan(0));
    expect(
      stats.newApplicants + stats.interviews,
      lessThanOrEqualTo(stats.totalApplicants),
    );
  });
}
