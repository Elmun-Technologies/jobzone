import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/data/employer_jobs_repository.dart';
import 'package:jobzone/features/employer/data/mock_employer.dart';

void main() {
  // No Supabase env in tests → the repository uses its in-memory store.
  group('EmployerJobsRepository (offline)', () {
    setUp(() => mockEmployer.resetJobsForTest());

    EmployerJobsRepository repo() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container.read(employerJobsRepositoryProvider);
    }

    test('myJobs returns the seeded c-acme jobs', () async {
      final jobs = await repo().myJobs();
      expect(jobs, isNotEmpty);
      expect(jobs.every((j) => j.companyId == MockEmployer.companyId), isTrue);
    });

    test('createJob prepends a job that is then visible in myJobs', () async {
      final r = repo();
      final before = (await r.myJobs()).length;

      final created = await r.createJob(
        title: 'Growth Lead',
        jobType: 'full_time',
      );
      expect(created.title, 'Growth Lead');
      expect(created.status, 'open');

      final after = await r.myJobs();
      expect(after.length, before + 1);
      expect(after.first.title, 'Growth Lead');
    });

    test('createJob defaults currency to UZS', () async {
      final created = await repo().createJob(title: 'Barista');
      expect(created.currency, 'UZS');
    });

    test('createJob keeps an explicit USD currency', () async {
      final created = await repo().createJob(
        title: 'Engineer',
        currency: 'USD',
      );
      expect(created.currency, 'USD');
    });

    test('createJob resolves a category id to its display name', () async {
      final created = await repo().createJob(
        title: 'Driver',
        categoryId: 'driver',
      );
      expect(created.categoryId, 'driver');
      expect(created.categoryName, 'Drivers');
    });

    test('setStatus flips a job and the status filter respects it', () async {
      final r = repo();
      final job = (await r.myJobs()).first;

      await r.setStatus(job.id, 'closed');

      final closed = await r.myJobs(status: 'closed');
      expect(closed.any((j) => j.id == job.id), isTrue);
      final open = await r.myJobs(status: 'open');
      expect(open.any((j) => j.id == job.id), isFalse);
    });
  });
}
