import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/data/applicants_repository.dart';
import 'package:jobzone/shared/enums/enums.dart';

void main() {
  // No Supabase env in tests → the repository uses its seeded in-memory store.
  group('ApplicantsRepository (offline)', () {
    ApplicantsRepository repo() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container.read(applicantsRepositoryProvider);
    }

    test('applicantsForJob returns only that job\'s applicants', () async {
      final forJob1 = await repo().applicantsForJob('mock-1');
      expect(forJob1, isNotEmpty);
      expect(forJob1.every((a) => a.jobId == 'mock-1'), isTrue);
    });

    test('allApplicants spans multiple jobs', () async {
      final all = await repo().allApplicants();
      expect(all.map((a) => a.jobId).toSet().length, greaterThan(1));
    });

    test('updateStatus advances status and appends to the timeline', () async {
      final r = repo();
      final applicant = (await r.allApplicants()).firstWhere(
        (a) => a.status == ApplicationStatus.submitted,
      );
      final beforeHistory = applicant.history.length;

      await r.updateStatus(applicant.id, ApplicationStatus.shortlisted);

      final history = await r.statusHistory(applicant.id);
      expect(history.length, beforeHistory + 1);
      expect(history.last.status, ApplicationStatus.shortlisted);

      final reloaded = (await r.allApplicants()).firstWhere(
        (a) => a.id == applicant.id,
      );
      expect(reloaded.status, ApplicationStatus.shortlisted);
    });
  });
}
