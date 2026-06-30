import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/flavors.dart';
import '../core/supabase/supabase_providers.dart';
import '../design_system/design_system.dart';
import '../features/notifications/application/push_providers.dart';
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

    // Register this device for push once the user is signed in. No-op unless
    // Firebase is configured (else pushServiceProvider is a NoopPushService).
    ref.listen(authStateChangesProvider, (_, next) {
      final event = next.value?.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession) {
        ref.read(pushServiceProvider).initialize();
      }
    });

    // Navigate to the relevant screen when the user taps a push notification.
    ref.listen(pushDeepLinksProvider, (_, next) {
      final path = next.value;
      if (path != null) router.push(path);
    });

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
