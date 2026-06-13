import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/flavors.dart';
import '../design_system/design_system.dart';
import '../localization/generated/app_localizations.dart';
import '../localization/locale_controller.dart';
import 'router/app_router.dart';

/// Root widget. Watches the router, theme mode and locale providers so the
/// whole app re-renders when the user changes appearance or language.
class JobzoneApp extends ConsumerWidget {
  const JobzoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: FlavorConfig.appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
