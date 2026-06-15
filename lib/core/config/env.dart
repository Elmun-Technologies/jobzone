/// Compile-time configuration, supplied via `--dart-define-from-file=env/<flavor>.json`.
///
/// All values default to empty so the app still builds/runs with no backend
/// configured (it then runs in "offline / no-backend" mode — useful for the
/// foundation phase, CI and widget tests).
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Edge Function endpoint for `search-jobs` (Meilisearch proxy).
  static const String searchProxyUrl = String.fromEnvironment(
    'SEARCH_PROXY_URL',
  );

  /// Agora App ID for real voice/video calls (Phase 8). Empty → calls use the
  /// simulated service. The App Certificate stays server-side (agora-token fn).
  static const String agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// True only when Supabase credentials are present.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// True when an Agora App ID is configured (enables real calls).
  static bool get hasAgora => agoraAppId.isNotEmpty;
}
