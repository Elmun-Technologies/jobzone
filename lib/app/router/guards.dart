import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../shared/providers/app_flags.dart';
import 'routes.dart';

/// Pure redirect decision for the router. Kept side-effect free so it can be
/// unit-tested as a truth table.
///
/// Order: onboarding slides → authentication → profile/preferences setup → app.
/// When Supabase isn't configured we skip gating entirely so the app still
/// boots to the shell (offline / dev mode).
String? resolveRedirect({
  required bool hasSupabase,
  required bool signedIn,
  required bool onboardingSeen,
  required bool profileComplete,
  required String location,
}) {
  if (!hasSupabase) return null;
  if (location == Routes.splash) return null; // splash performs the first hop

  final inAuth = location == Routes.welcome || location.startsWith('/auth');
  final inOnboarding = location == Routes.onboarding;
  final inSetup =
      location == Routes.completeProfile ||
      location.startsWith('/setup') ||
      location.startsWith('/permissions');

  if (!onboardingSeen) return inOnboarding ? null : Routes.onboarding;
  if (!signedIn) return inAuth ? null : Routes.signIn;
  if (!profileComplete) return inSetup ? null : Routes.completeProfile;
  if (inAuth || inOnboarding) return Routes.home;
  return null;
}

/// Binds [resolveRedirect] to current app state.
String? redirectFromRef(Ref ref, String location) {
  return resolveRedirect(
    hasSupabase: Env.hasSupabase,
    signedIn: ref.read(currentSessionProvider) != null,
    onboardingSeen: ref.read(appFlagsProvider).onboardingSeen,
    profileComplete: ref.read(appFlagsProvider).profileComplete,
    location: location,
  );
}

/// Lightweight [Listenable] for `GoRouter.refreshListenable`.
class RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}
