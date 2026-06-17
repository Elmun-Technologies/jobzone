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

    test('addPerson / removePerson mutate the team list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(companyAdminRepositoryProvider);

      final before = (await repo.people()).length;
      await repo.addPerson(name: 'Olim', title: 'CTO', isRecruiter: true);
      final after = await repo.people();
      expect(after.length, before + 1);

      final added = after.firstWhere((p) => p.name == 'Olim');
      expect(added.isRecruiter, isTrue);
      await repo.removePerson(added.id);
      expect((await repo.people()).any((p) => p.id == added.id), isFalse);
    });

    test('addGalleryItem / removeGalleryItem mutate the gallery', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(companyAdminRepositoryProvider);

      final before = (await repo.gallery()).length;
      await repo.addGalleryItem(
        mediaUrl: 'https://example.com/p.jpg',
        caption: 'New',
      );
      final after = await repo.gallery();
      expect(after.length, before + 1);

      final added = after.firstWhere((g) => g.caption == 'New');
      await repo.removeGalleryItem(added.id);
      expect((await repo.gallery()).any((g) => g.id == added.id), isFalse);
    });
  });
}
