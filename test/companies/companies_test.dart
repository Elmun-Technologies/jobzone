import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/companies/data/companies_repository.dart';
import 'package:jobzone/features/companies/domain/company.dart';
import 'package:jobzone/features/jobs/data/jobs_repository_impl.dart';

void main() {
  // Offline mode (no Supabase env under `flutter test`).
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('CompaniesRepository (offline)', () {
    test('byId returns a seeded company, null for unknown', () async {
      final repo = container.read(companiesRepositoryProvider);
      final acme = await repo.byId('c-acme');
      expect(acme, isNotNull);
      expect(acme!.name, 'Acme');
      expect(acme.isVerified, isTrue);
      expect(acme.hasIntroVideo, isTrue);
      expect(await repo.byId('does-not-exist'), isNull);
    });

    test('people and gallery are scoped to the company', () async {
      final repo = container.read(companiesRepositoryProvider);
      final people = await repo.people('c-acme');
      expect(people, isNotEmpty);
      expect(people.any((p) => p.isRecruiter), isTrue);

      final gallery = await repo.gallery('c-acme');
      expect(gallery, isNotEmpty);
    });
  });

  group('JobsRepository.byCompany (offline)', () {
    test('returns only that company\'s jobs', () async {
      final jobs = container.read(jobsRepositoryProvider);
      final acmeJobs = await jobs.byCompany('c-acme');
      expect(acmeJobs, isNotEmpty);
      expect(acmeJobs.every((j) => j.companyId == 'c-acme'), isTrue);

      final nimbusJobs = await jobs.byCompany('c-nimbus');
      expect(nimbusJobs.every((j) => j.companyId == 'c-nimbus'), isTrue);
    });
  });

  group('Company.fromMap', () {
    test('parses verification audit fields', () {
      final c = Company.fromMap({
        'id': 'c1',
        'name': 'Globex',
        'is_verified': true,
        'verification_method': 'licensed_agency',
        'verified_at': '2026-06-20T00:00:00Z',
      });
      expect(c.isVerified, isTrue);
      expect(c.verificationMethod, 'licensed_agency');
      expect(c.verifiedAt, isNotNull);
    });
  });
}
