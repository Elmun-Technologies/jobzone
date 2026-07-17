/// Compile-time configuration, supplied via `--dart-define-from-file=env/<flavor>.json`
/// or `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…` on the
/// build command line.
///
/// Supabase connection: EMPTY when the dart-defines aren't passed. There is
/// deliberately NO baked-in fallback backend — the earlier "hardcoded demo
/// Supabase URL for release builds" leaked into production risk (a store build
/// missing the CI dart-defines would silently talk to a different project than
/// the one Vercel + edge functions + admin panel are configured for). Now
/// `hasSupabase` returns false in that case, `bootstrap()` refuses to boot
/// with a "misconfigured build" screen, and the release AAB/IPA fails loud —
/// which is the invariant the launch checklist assumes.
///
/// The CI build workflows (`android-apk.yml`, `web-deploy.yml`, iOS Fastlane)
/// pass the production project's URL + publishable key as dart-defines;
/// unit tests drive the repos through the empty-env branch, which routes to
/// each feature's in-memory mock substrate.
class Env {
  const Env._();

  static const String _definedSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _definedSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Resolved Supabase URL — the explicit dart-define, else empty. Empty
  /// implies `hasSupabase == false`, which routes debug/test builds through
  /// the offline mock branch and forces release builds into the
  /// "misconfigured build" screen (see [_MissingConfigApp] in bootstrap.dart).
  static String get supabaseUrl => _definedSupabaseUrl;

  /// Resolved Supabase publishable key, same precedence as [supabaseUrl].
  static String get supabaseAnonKey => _definedSupabaseAnonKey;

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
