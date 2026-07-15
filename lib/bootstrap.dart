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

  // The product is online-only: a binary built without Supabase credentials
  // must never reach users looking like a working app (the repos' offline
  // seams exist purely as the unit-test substrate). Fail loudly instead of
  // booting into demo content.
  if (!Env.hasSupabase) {
    runApp(const _MissingConfigApp());
    return;
  }

  // Load date-symbol data for every locale so DateFormat can render month/day
  // names in uz/ru (not just en_US) once Intl.defaultLocale is set to the
  // in-app language (see YollaApp.builder).
  await initializeDateFormatting();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    // Supabase's new publishable key (sb_publishable_…); a legacy anon key
    // also works here for existing projects.
    publishableKey: Env.supabaseAnonKey,
  );

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

/// Shown instead of the app when the build carries no Supabase credentials —
/// a developer-facing dead end (uz first, like the product), never meant for
/// store builds. Deliberately l10n-free: it renders before any app scaffolding.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFC7FB00),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ilova sozlanmagan',
                  style: TextStyle(
                    color: Color(0xFFF3F3F1),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supabase kalitlarisiz qurilgan build.\n'
                  'This build was compiled without SUPABASE_URL / '
                  'SUPABASE_ANON_KEY dart-defines.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF3F3F1).withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
