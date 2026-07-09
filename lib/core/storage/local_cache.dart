import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The loaded [SharedPreferences] instance. Overridden in `bootstrap.dart`
/// once the async load completes, so the rest of the app can read it
/// synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap()',
  ),
);

/// Keys used for primitive local persistence (locale, theme, onboarding flag).
abstract final class CacheKeys {
  static const String locale = 'pref_locale';
  static const String themeMode = 'pref_theme_mode';
  static const String onboardingComplete = 'pref_onboarding_complete';
  static const String profileSetupComplete = 'pref_profile_setup_complete';
  static const String userRole = 'pref_user_role';
  static const String userRoleChosen = 'pref_user_role_chosen';
  static const String bookmarks = 'pref_bookmarks';
  static const String dismissedJobs = 'pref_dismissed_jobs';
  static const String recentSearches = 'pref_recent_searches';
}
