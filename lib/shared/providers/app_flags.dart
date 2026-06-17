import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_cache.dart';
import '../enums/enums.dart';

/// App-wide onboarding flags that gate navigation, persisted in
/// SharedPreferences. The router watches this (plus auth state) to redirect.
class AppFlags {
  const AppFlags({
    required this.onboardingSeen,
    required this.profileComplete,
    this.role = UserRole.jobSeeker,
  });

  final bool onboardingSeen;
  final bool profileComplete;

  /// Which experience the user gets. Read synchronously by the router redirect,
  /// so it lives here (locally persisted) rather than only on `profiles.role` —
  /// offline/dev mode has no session to read a role from.
  final UserRole role;

  AppFlags copyWith({
    bool? onboardingSeen,
    bool? profileComplete,
    UserRole? role,
  }) => AppFlags(
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    profileComplete: profileComplete ?? this.profileComplete,
    role: role ?? this.role,
  );
}

class AppFlagsController extends Notifier<AppFlags> {
  @override
  AppFlags build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppFlags(
      onboardingSeen: prefs.getBool(CacheKeys.onboardingComplete) ?? false,
      profileComplete: prefs.getBool(CacheKeys.profileSetupComplete) ?? false,
      role:
          UserRole.fromWire(prefs.getString(CacheKeys.userRole)) ??
          UserRole.jobSeeker,
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

  Future<void> setRole(UserRole role) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(CacheKeys.userRole, role.wire);
    state = state.copyWith(role: role);
  }
}

final appFlagsProvider = NotifierProvider<AppFlagsController, AppFlags>(
  AppFlagsController.new,
);

/// Convenience read alias for the current account role. Lets feature code
/// depend on the role without reaching into [AppFlags].
final currentUserRoleProvider = Provider<UserRole>(
  (ref) => ref.watch(appFlagsProvider).role,
);
