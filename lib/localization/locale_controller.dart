import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/local_cache.dart';

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
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
