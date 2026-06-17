import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jobzone/core/storage/local_cache.dart';
import 'package:jobzone/shared/enums/enums.dart';
import 'package:jobzone/shared/providers/app_flags.dart';

void main() {
  group('AppFlags role', () {
    test(
      'defaults to job seeker and setRole persists + updates provider',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(container.read(appFlagsProvider).role, UserRole.jobSeeker);
        expect(container.read(currentUserRoleProvider), UserRole.jobSeeker);

        await container
            .read(appFlagsProvider.notifier)
            .setRole(UserRole.employer);

        expect(container.read(appFlagsProvider).role, UserRole.employer);
        expect(container.read(currentUserRoleProvider), UserRole.employer);
        expect(prefs.getString(CacheKeys.userRole), 'employer');
      },
    );

    test('hydrates the persisted role on build', () async {
      SharedPreferences.setMockInitialValues({CacheKeys.userRole: 'employer'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(appFlagsProvider).role, UserRole.employer);
    });
  });
}
