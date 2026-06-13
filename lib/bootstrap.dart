import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/storage/local_cache.dart';

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

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const JobzoneApp(),
    ),
  );
}
