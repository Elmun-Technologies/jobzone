import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jobzone/core/storage/local_cache.dart';
import 'package:jobzone/design_system/design_system.dart';
import 'package:jobzone/features/auth/presentation/pages/choose_role_page.dart';
import 'package:jobzone/localization/generated/app_localizations.dart';

void main() {
  testWidgets('Choose-role page offers both roles and a continue action', (
    tester,
  ) async {
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
          home: const ChooseRolePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("I'm looking for a job"), findsOneWidget);
    expect(find.text("I'm hiring"), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
