import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_cache.dart';

/// Holds the current [ThemeMode], persisted in SharedPreferences.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref
        .read(sharedPreferencesProvider)
        .getString(CacheKeys.themeMode);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      // Default to LIGHT, not system. Yolla is a light-first brand (paper
      // background, ink primary) and the dark theme isn't fully audited yet —
      // several screens hardcode light-on-`primary` colors that invert to
      // white-on-near-white in dark mode ("washed out"). Until dark mode is
      // hardened + a real in-app toggle ships, everyone gets the polished
      // light design regardless of the device setting.
      _ => ThemeMode.light,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await ref
        .read(sharedPreferencesProvider)
        .setString(CacheKeys.themeMode, value);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
