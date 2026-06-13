import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jobzone/core/storage/local_cache.dart';
import 'package:jobzone/design_system/design_system.dart';
import 'package:jobzone/features/onboarding/presentation/welcome_page.dart';
import 'package:jobzone/localization/generated/app_localizations.dart';

void main() {
  testWidgets('Welcome page renders the localized CTA', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const WelcomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
