import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/storage/local_cache.dart';
import '../core/supabase/supabase_providers.dart';

/// Locales the app ships with. English is the fallback.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('ru'),
  Locale('uz'),
];

/// Holds the user-selected [Locale] (null = follow the system locale),
/// persisted in SharedPreferences. The Language screen drives this; because
/// `MaterialApp.router` watches it, the whole UI re-renders without a restart.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    // Most users pick their language once, on the first-run screen, before
    // they have an account to write it to — so signing in is the other moment
    // the profile has to learn it, not just a later change of mind.
    ref.listen(currentUserIdProvider, (previous, next) {
      if (next != null && next != previous) unawaited(_publishToProfile(state));
    });
    final code = ref
        .read(sharedPreferencesProvider)
        .getString(CacheKeys.locale);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(CacheKeys.locale);
    } else {
      await prefs.setString(CacheKeys.locale, locale.languageCode);
    }
    await _publishToProfile(locale);
  }

  /// Mirrors the choice into `profiles.preferred_locale`.
  ///
  /// SharedPreferences alone only tells *this device*. Everything the backend
  /// sends outward — Telegram messages, FCM push — is composed server-side,
  /// where the device's preference is invisible, so without this the column
  /// keeps its 0001 default of 'en' for every user who ever installed the app
  /// and every push goes out in a language most of them do not read.
  ///
  /// Best-effort by design: a guest has no row to write, and a language change
  /// must never fail or block on the network.
  Future<void> _publishToProfile(Locale? locale) async {
    if (!Env.hasSupabase) return;
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    // Null means "follow the system"; store what that resolves to now, since
    // the server has no way to ask the device later. An unsupported system
    // language falls back to 'en' — the same thing the app itself shows.
    final code =
        locale?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final supported = kSupportedLocales.any((l) => l.languageCode == code)
        ? code
        : 'en';
    try {
      await client
          .from('profiles')
          .update({'preferred_locale': supported})
          .eq('id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('preferred_locale update failed → $e');
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
