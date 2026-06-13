import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_cache.dart';

/// App-wide onboarding flags that gate navigation, persisted in
/// SharedPreferences. The router watches this (plus auth state) to redirect.
class AppFlags {
  const AppFlags({required this.onboardingSeen, required this.profileComplete});

  final bool onboardingSeen;
  final bool profileComplete;

  AppFlags copyWith({bool? onboardingSeen, bool? profileComplete}) => AppFlags(
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    profileComplete: profileComplete ?? this.profileComplete,
  );
}

class AppFlagsController extends Notifier<AppFlags> {
  @override
  AppFlags build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppFlags(
      onboardingSeen: prefs.getBool(CacheKeys.onboardingComplete) ?? false,
      profileComplete: prefs.getBool(CacheKeys.profileSetupComplete) ?? false,
    );
  }

  Future<void> markOnboardingSeen() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(CacheKeys.onboardingComplete, true);
    state = state.copyWith(onboardingSeen: true);
  }

  Future<void> setProfileComplete(bool value) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(CacheKeys.profileSetupComplete, value);
    state = state.copyWith(profileComplete: value);
  }
}

final appFlagsProvider = NotifierProvider<AppFlagsController, AppFlags>(
  AppFlagsController.new,
);
