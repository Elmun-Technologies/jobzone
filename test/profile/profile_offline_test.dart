import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/features/profile/data/cv_repository.dart';
import 'package:jobzone/features/profile/data/profile_repository.dart';
import 'package:jobzone/features/profile/domain/cv_models.dart';
import 'package:jobzone/shared/enums/enums.dart';

void main() {
  // Offline mode: edits via CvRepository must surface through ProfileRepository,
  // which now reads the shared offline profile store (not a const mock).
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('savePersonalInfo is reflected by the loaded profile', () async {
    final cv = container.read(cvRepositoryProvider);
    await cv.savePersonalInfo(
      fullName: 'Test User',
      phone: '+1 555 0100',
      city: 'Berlin',
      country: 'DE',
    );

    final profile = await container.read(profileRepositoryProvider).load();
    expect(profile, isNotNull);
    expect(profile!.fullName, 'Test User');
    expect(profile.phone, '+1 555 0100');
    expect(profile.city, 'Berlin');
    expect(profile.country, 'DE');
  });

  test('setSeekingStatus round-trips through the profile', () async {
    final cv = container.read(cvRepositoryProvider);
    await cv.setSeekingStatus(SeekingStatus.notLooking, openToWork: false);

    final profile = await container.read(profileRepositoryProvider).load();
    expect(profile!.seekingStatus, SeekingStatus.notLooking);
    expect(profile.isOpenToWork, isFalse);
  });

  test('worker-card fields load offline and confirmPhone verifies', () async {
    final repo = container.read(profileRepositoryProvider);
    final before = (await repo.load())!;
    expect(before.workerVerified, isTrue);
    expect(before.phoneVerified, isFalse);
    expect(before.desiredPayMin, isNotNull);
    expect(before.availability, 'immediate');

    await repo.confirmPhone();
    expect((await repo.load())!.phoneVerified, isTrue);
  });

  test('saved experience appears in the loaded profile', () async {
    final cv = container.read(cvRepositoryProvider);
    final before = (await container.read(profileRepositoryProvider).load())!
        .experiences
        .length;

    await cv.saveExperience(const Experience(title: 'Solutions Architect'));

    final loaded = (await container.read(profileRepositoryProvider).load())!;
    expect(loaded.experiences.length, before + 1);
    expect(
      loaded.experiences.any((e) => e.title == 'Solutions Architect'),
      isTrue,
    );
  });
}
