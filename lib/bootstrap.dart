import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/storage/local_cache.dart';
import 'features/notifications/application/push_providers.dart';
import 'shared/widgets/jz_map/jz_map.dart';

/// Shared startup path for every flavor entrypoint. Initializes Supabase (only
/// when credentials are configured), loads SharedPreferences, and runs the app
/// inside a [ProviderScope].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load date-symbol data for every locale so DateFormat can render month/day
  // names in uz/ru (not just en_US) once Intl.defaultLocale is set to the
  // in-app language (see YollaApp.builder).
  await initializeDateFormatting();

  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // Supabase's new publishable key (sb_publishable_…); a legacy anon key
      // also works here for existing projects.
      publishableKey: Env.supabaseAnonKey,
    );
  }

  // Firebase enables FCM push. It throws without native config
  // (google-services.json / GoogleService-Info.plist) — e.g. on web or in dev —
  // so we guard it: push simply stays disabled (NoopPushService) until the
  // host app ships Firebase config. See docs/phase-8-realtime-and-push.md.
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  // Map SDK init: on mobile this boots the official Yandex MapKit (must run
  // before the first map view); on web it's a no-op (the OSM map needs no
  // setup). Guarded so a native init failure degrades to a blank map rather
  // than blocking app startup.
  try {
    await initJzMap();
  } catch (_) {
    // Non-fatal: map views simply render empty until the SDK can init.
  }

  final prefs = await SharedPreferences.getInstance();

  // Wrap runApp() with SentryFlutter.init when a DSN is baked in via
  // --dart-define=SENTRY_DSN=…. Without a DSN we call runApp directly:
  // the offline/mock demo and tests must not touch the network. The
  // wrapper also captures uncaught Flutter/PlatformDispatcher errors and
  // sends them to Sentry (SentryFlutter registers those hooks itself).
  Widget appRoot() => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const YollaApp(),
  );

  if (Env.hasSentry) {
    await SentryFlutter.init((options) {
      options.dsn = Env.sentryDsn;
      // Same flavor label used by CI builds so a stray dev crash never
      // shows up in the production Sentry inbox.
      options.environment = Env.flavor;
      // Full sampling at launch — dial down once traffic climbs so we
      // don't burn the free-tier quota (10k perf events / month).
      options.tracesSampleRate = 1.0;
      // Session replay opt-in — off by default so salary/CV inputs are
      // never captured; flip via options.replay.* when we're ready.
    }, appRunner: () => runApp(appRoot()));
  } else {
    runApp(appRoot());
  }
}
