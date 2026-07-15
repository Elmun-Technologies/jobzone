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
///   3. otherwise (debug — `flutter run`, `flutter test`, CI) → empty. Unit
///      tests drive the repos' offline branch through this; a booted app never
///      gets that far — `bootstrap()` fails fast into a "misconfigured build"
///      screen (the product is online-only, no demo content may ever render).
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

  /// Public web origin the mobile pay flow sends the gateway back to (the Payme/
  /// Click `return_url` lands on the web `/employer/jobs/:id/paid` page). Only
  /// the landing page differs by build; the app polls the order itself.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://yollla.uz',
  );

  /// Direct pay-per-listing (Payme/Click) merchant ids. PUBLIC — they only
  /// address the checkout; the secret webhook keys live server-side in the edge
  /// functions. Empty → the pay screen reports "online payment not set up yet".
  static const String paymeMerchantId = String.fromEnvironment(
    'PAYME_MERCHANT_ID',
  );
  static const String clickServiceId = String.fromEnvironment(
    'CLICK_SERVICE_ID',
  );
  static const String clickMerchantId = String.fromEnvironment(
    'CLICK_MERCHANT_ID',
  );

  /// Rahmat (Multicard) is on-off — the client holds no merchant credentials.
  /// The `rahmat-invoice` edge fn authenticates to Multicard and returns a
  /// hosted checkout URL when this flag is set. Toggle at build time with
  /// `--dart-define=RAHMAT_ENABLED=1`.
  static const bool rahmatEnabled = bool.fromEnvironment('RAHMAT_ENABLED');

  /// Sentry DSN — enables client-side crash + performance reporting when a
  /// non-empty value is supplied via `--dart-define=SENTRY_DSN=…`. Empty →
  /// bootstrap skips SentryFlutter.init entirely and the app runs raw, which
  /// keeps the offline demo / test substrate free of network chatter.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// True only when Supabase credentials are present.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// True when an Agora App ID is configured (enables real calls).
  static bool get hasAgora => agoraAppId.isNotEmpty;

  /// True when at least one gateway (Payme, Click, or Rahmat) can be used.
  static bool get hasPayme => paymeMerchantId.isNotEmpty;
  static bool get hasClick =>
      clickServiceId.isNotEmpty && clickMerchantId.isNotEmpty;
  static bool get hasRahmat => rahmatEnabled && hasSupabase;
  static bool get hasPaymentGateway => hasPayme || hasClick || hasRahmat;

  /// True when a Sentry DSN is baked in — bootstrap only wires SentryFlutter
  /// in that case, so debug/test/offline builds stay silent.
  static bool get hasSentry => sentryDsn.isNotEmpty;
}
