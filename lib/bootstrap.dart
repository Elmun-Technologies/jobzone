import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/storage/local_cache.dart';
import 'features/notifications/application/push_providers.dart';

/// Shared startup path for every flavor entrypoint. Initializes Supabase (only
/// when credentials are configured), loads SharedPreferences, and runs the app
/// inside a [ProviderScope].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const YollaApp(),
    ),
  );
}
