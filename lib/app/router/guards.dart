import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../shared/enums/enums.dart';
import '../../shared/providers/app_flags.dart';
import 'routes.dart';

/// Pure redirect decision for the router. Kept side-effect free so it can be
/// unit-tested as a truth table.
///
/// Order: onboarding slides → authentication → profile/preferences setup → app.
/// After setup, [role] keeps each account type in its own area: job seekers in
/// the bottom-nav shell, employers in the `/employer` (Yolla Business) shell.
/// When Supabase isn't configured we skip gating entirely so the app still
/// boots to the shell (offline / dev mode), and [role] defaults to
/// [UserRole.jobSeeker] so existing seeker behavior is unchanged.
String? resolveRedirect({
  required bool hasSupabase,
  required bool signedIn,
  required bool onboardingSeen,
  required bool profileComplete,
  required String location,
  UserRole role = UserRole.jobSeeker,
  bool roleChosen = false,
}) {
  if (!hasSupabase) return null;
  if (location == Routes.splash) return null; // splash performs the first hop

  final isEmployer = role == UserRole.employer;
  // Password reset rides a recovery session (signed-in), so it must stay
  // reachable even when onboarded — don't treat it as an auth screen to bounce.
  final inAuth =
      (location == Routes.welcome || location.startsWith('/auth')) &&
      location != Routes.newPassword;
  final inOnboarding = location == Routes.onboarding;
  final inEmployerArea = location.startsWith('/employer');
  // Chat + calls (`/chat/:id/call/...`) are shared by both roles — employers
  // message candidates from there too.
  final inShared = location.startsWith(Routes.chat);

  // The allowed "setup" zone differs by role: seekers run the preference +
  // permission chain; employers complete their profile then create a company.
  // The role-choice screen is allowed for both (it precedes complete-profile).
  final inSetup =
      location == Routes.chooseRole ||
      location == Routes.completeProfile ||
      (isEmployer
          ? location == Routes.employerOnboard
          : (location.startsWith('/setup') ||
                location.startsWith('/permissions')));

  if (!onboardingSeen) return inOnboarding ? null : Routes.onboarding;
  if (!signedIn) return inAuth ? null : Routes.signIn;
  if (!profileComplete) {
    // New accounts must pick a role first. The guard enforces this (not just
    // per-screen navigation) so Google OAuth — which has no explicit
    // post-signup hop — also lands on the role-choice screen.
    if (!roleChosen) {
      return location == Routes.chooseRole ? null : Routes.chooseRole;
    }
    return inSetup ? null : Routes.completeProfile;
  }

  // Past setup: keep each role inside its own area, but allow the shared chat
  // surface and the password-reset screen for both.
  if (isEmployer) {
    if (inEmployerArea || inShared || location == Routes.newPassword) {
      return null;
    }
    return Routes.employerDashboard;
  }
  if (inAuth || inOnboarding || inEmployerArea) return Routes.home;
  return null;
}

/// Binds [resolveRedirect] to current app state.
String? redirectFromRef(Ref ref, String location) {
  return resolveRedirect(
    hasSupabase: Env.hasSupabase,
    signedIn: ref.read(currentSessionProvider) != null,
    onboardingSeen: ref.read(appFlagsProvider).onboardingSeen,
    profileComplete: ref.read(appFlagsProvider).profileComplete,
    role: ref.read(appFlagsProvider).role,
    roleChosen: ref.read(appFlagsProvider).roleChosen,
    location: location,
  );
}

/// Lightweight [Listenable] for `GoRouter.refreshListenable`.
class RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}
