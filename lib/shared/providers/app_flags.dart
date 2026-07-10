import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_cache.dart';
import '../enums/enums.dart';

/// App-wide onboarding flags that gate navigation, persisted in
/// SharedPreferences. The router watches this (plus auth state) to redirect.
class AppFlags {
  const AppFlags({
    required this.onboardingSeen,
    required this.languageChosen,
    required this.profileComplete,
    this.role = UserRole.jobSeeker,
    this.roleChosen = false,
  });

  final bool onboardingSeen;

  /// Whether the user has picked a language on the first-run picker (the hop
  /// after onboarding). Device-wide, so it survives sign-out like
  /// [onboardingSeen] — you only choose your language once.
  final bool languageChosen;

  final bool profileComplete;

  /// Which experience the user gets. Read synchronously by the router redirect,
  /// so it lives here (locally persisted) rather than only on `profiles.role` —
  /// offline/dev mode has no session to read a role from.
  final UserRole role;

  /// Whether the user has explicitly picked a role (vs the [role] default). New
  /// accounts must choose at registration before proceeding (incl. Google).
  final bool roleChosen;

  AppFlags copyWith({
    bool? onboardingSeen,
    bool? languageChosen,
    bool? profileComplete,
    UserRole? role,
    bool? roleChosen,
  }) => AppFlags(
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    languageChosen: languageChosen ?? this.languageChosen,
    profileComplete: profileComplete ?? this.profileComplete,
    role: role ?? this.role,
    roleChosen: roleChosen ?? this.roleChosen,
  );
}

class AppFlagsController extends Notifier<AppFlags> {
  @override
  AppFlags build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppFlags(
      onboardingSeen: prefs.getBool(CacheKeys.onboardingComplete) ?? false,
      languageChosen: prefs.getBool(CacheKeys.languageChosen) ?? false,
      profileComplete: prefs.getBool(CacheKeys.profileSetupComplete) ?? false,
      role:
          UserRole.fromWire(prefs.getString(CacheKeys.userRole)) ??
          UserRole.jobSeeker,
      roleChosen: prefs.getBool(CacheKeys.userRoleChosen) ?? false,
    );
  }

  Future<void> markOnboardingSeen() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(CacheKeys.onboardingComplete, true);
    state = state.copyWith(onboardingSeen: true);
  }

  Future<void> markLanguageChosen() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(CacheKeys.languageChosen, true);
    state = state.copyWith(languageChosen: true);
  }

  Future<void> setProfileComplete(bool value) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(CacheKeys.profileSetupComplete, value);
    state = state.copyWith(profileComplete: value);
  }

  Future<void> setRole(UserRole role) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(CacheKeys.userRole, role.wire);
    await prefs.setBool(CacheKeys.userRoleChosen, true);
    state = state.copyWith(role: role, roleChosen: true);
  }

  /// Clears per-account onboarding state on sign-out so the next account starts
  /// clean (re-chooses role + completes its own setup). Onboarding-seen stays.
  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(CacheKeys.profileSetupComplete);
    await prefs.remove(CacheKeys.userRole);
    await prefs.remove(CacheKeys.userRoleChosen);
    state = state.copyWith(
      profileComplete: false,
      role: UserRole.jobSeeker,
      roleChosen: false,
    );
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
