import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/profile/data/cv_repository.dart';
import 'package:jobzone/features/profile/domain/cv_models.dart';

void main() {
  // No Supabase env is defined under `flutter test`, so the repository runs in
  // offline (in-memory) mode. Assertions use deltas to stay independent of the
  // shared seed data / test ordering.
  late ProviderContainer container;
  late CvRepository repo;

  setUp(() {
    container = ProviderContainer();
    repo = container.read(cvRepositoryProvider);
  });

  tearDown(() => container.dispose());

  group('experiences', () {
    test('insert adds an entry, update mutates in place', () async {
      final before = (await repo.experiences()).length;

      await repo.saveExperience(
        const Experience(title: 'QA Engineer', companyName: 'Testco'),
      );
      final afterInsert = await repo.experiences();
      expect(afterInsert.length, before + 1);

      final created = afterInsert.firstWhere((e) => e.title == 'QA Engineer');
      expect(created.id, isNotNull);

      await repo.saveExperience(
        Experience(id: created.id, title: 'Senior QA Engineer'),
      );
      final afterUpdate = await repo.experiences();
      expect(afterUpdate.length, before + 1, reason: 'update must not add');
      expect(afterUpdate.any((e) => e.title == 'Senior QA Engineer'), isTrue);

      await repo.deleteExperience(created.id!);
      expect((await repo.experiences()).length, before);
    });
  });

  group('skills', () {
    test('setSkills replaces, trims and de-dupes', () async {
      await repo.setSkills(['Go', ' Go ', 'Rust', '']);
      final skills = await repo.skills();
      expect(skills, containsAll(['Go', 'Rust']));
      expect(skills.where((s) => s == 'Go').length, 1);
      expect(skills.contains(''), isFalse);
    });
  });

  group('contact info', () {
    test('saved values round-trip', () async {
      await repo.saveContactInfo(
        const ContactInfo(website: 'https://x.dev', github: 'octocat'),
      );
      final info = await repo.contactInfo();
      expect(info.website, 'https://x.dev');
      expect(info.github, 'octocat');
    });
  });

  group('resumes', () {
    test('add then set-default flips the default flag', () async {
      await repo.addResume(
        title: 'My CV',
        fileName: 'cv.pdf',
        bytes: Uint8List.fromList(List.filled(10, 0)),
      );
      final list = await repo.resumes();
      final added = list.firstWhere((r) => r.title == 'My CV');

      await repo.setDefaultResume(added.id!);
      final after = await repo.resumes();
      expect(after.firstWhere((r) => r.id == added.id).isDefault, isTrue);
      // Exactly one default at a time.
      expect(after.where((r) => r.isDefault).length, 1);
    });
  });
}
