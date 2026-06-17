import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/employer/data/company_admin_repository.dart';
import 'package:jobzone/features/employer/data/mock_employer.dart';

void main() {
  // No Supabase env in tests, so the repository uses its in-memory store.
  group('CompanyAdminRepository (offline)', () {
    setUp(() => mockEmployer.company = null);

    test('starts with no company', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(companyAdminRepositoryProvider);

      expect(await repo.myCompany(), isNull);
    });

    test(
      'createCompany persists the company and myCompany returns it',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final repo = container.read(companyAdminRepositoryProvider);

        final created = await repo.createCompany(
          name: 'Globex',
          industry: 'Software',
          size: '51–200',
          about: 'We build things.',
        );

        expect(created.id, MockEmployer.companyId);
        expect(created.name, 'Globex');
        expect(created.industry, 'Software');

        final loaded = await repo.myCompany();
        expect(loaded?.name, 'Globex');
        expect(loaded?.about, 'We build things.');
      },
    );

    test('updateCompany overwrites the stored company', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(companyAdminRepositoryProvider);

      await repo.createCompany(name: 'Globex');
      final created = await repo.myCompany();
      await repo.updateCompany(
        created!.copyWith(name: 'Globex Corp', about: 'Updated'),
      );

      final loaded = await repo.myCompany();
      expect(loaded?.name, 'Globex Corp');
      expect(loaded?.about, 'Updated');
    });
  });
}
