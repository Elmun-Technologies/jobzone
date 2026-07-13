import 'package:flutter/foundation.dart' show kDebugMode;

/// Compile-time configuration, supplied via `--dart-define-from-file=env/<flavor>.json`.
///
/// Supabase connection precedence (see [supabaseUrl] / [supabaseAnonKey]):
///   1. an explicit `--dart-define=SUPABASE_URL=…` — what the CI build
///      workflows pass (`android-apk.yml`, `web-deploy.yml`);
///   2. otherwise, in **non-debug (release/profile) builds only**, a baked-in
///      fallback to the public Yolla demo backend. This is the fix for the
///      iOS↔Android split: a shipped build that was compiled without the
///      dart-defines (e.g. a bare Xcode iOS build) now behaves like Android and
///      web instead of silently dropping into offline/mock mode;
///   3. otherwise (debug — `flutter run`, `flutter test`, CI) → empty, i.e.
///      offline/mock mode. This keeps the offline demo + test substrate intact
///      (product invariant: everything runs offline with no backend).
///
/// The fallback values are the same client-safe, RLS-protected **publishable**
/// key the web demo and the Android APK already ship in their bundles — nothing
/// secret is exposed here that isn't already public.
class Env {
  const Env._();

  // Public demo backend — mirrors the keys baked into the CI build workflows.
  static const String _fallbackSupabaseUrl =
      'https://nzxdnsxwxrstcrumwzwu.supabase.co';
  static const String _fallbackSupabaseAnonKey =
      'sb_publishable_3OcEGaXAaF0x5bClTA_PkA_e6FvbeGG';

  static const String _definedSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _definedSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Resolved Supabase URL — the explicit dart-define, else the demo-backend
  /// fallback in release/profile builds, else empty (offline) in debug/tests.
  static String get supabaseUrl => _definedSupabaseUrl.isNotEmpty
      ? _definedSupabaseUrl
      : (kDebugMode ? '' : _fallbackSupabaseUrl);

  /// Resolved Supabase publishable key, with the same precedence as
  /// [supabaseUrl] so the two never disagree.
  static String get supabaseAnonKey => _definedSupabaseAnonKey.isNotEmpty
      ? _definedSupabaseAnonKey
      : (kDebugMode ? '' : _fallbackSupabaseAnonKey);

  /// Edge Function endpoint for `search-jobs` (Meilisearch proxy).
  static const String searchProxyUrl = String.fromEnvironment(
    'SEARCH_PROXY_URL',
  );

  /// Agora App ID for real voice/video calls (Phase 8). Empty → calls use the
  /// simulated service. The App Certificate stays server-side (agora-token fn).
  static const String agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  /// Telegram bot username (without `@`) used to build the `t.me` link for the
  /// notify-bridge handshake. Empty → the connect flow shows the `/start`
  /// command instead of a deep link.
  static const String telegramBot = String.fromEnvironment('TELEGRAM_BOT');

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
