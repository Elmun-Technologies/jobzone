import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jobzone/core/storage/local_cache.dart';
import 'package:jobzone/core/utils/validators.dart';
import 'package:jobzone/design_system/design_system.dart';
import 'package:jobzone/features/auth/presentation/pages/phone_sign_in_page.dart';
import 'package:jobzone/features/auth/presentation/util/uz_phone_input_formatter.dart';
import 'package:jobzone/localization/generated/app_localizations.dart';

void main() {
  group('Validators.e164Phone', () {
    test('normalizes common Uzbek input shapes', () {
      expect(Validators.e164Phone('+998 90 123 45 67'), '+998901234567');
      expect(Validators.e164Phone('998901234567'), '+998901234567');
      expect(Validators.e164Phone('00998901234567'), '+998901234567');
    });

    test('rejects values that cannot be E.164', () {
      expect(Validators.e164Phone('90 123 45 67'), isNull); // no country code
      expect(Validators.e164Phone('+12'), isNull); // too short
      expect(Validators.e164Phone('abc'), isNull);
    });
  });

  group('Validators.uzLocalPhoneE164', () {
    test('prepends +998 to the nine national digits, ignoring spacing', () {
      expect(Validators.uzLocalPhoneE164('90 123 45 67'), '+998901234567');
      expect(Validators.uzLocalPhoneE164('901234567'), '+998901234567');
    });

    test('rejects a national part that is not exactly nine digits', () {
      expect(Validators.uzLocalPhoneE164('90 123 45'), isNull); // too short
      expect(Validators.uzLocalPhoneE164('90 123 45 678'), isNull); // too long
      expect(Validators.uzLocalPhoneE164(''), isNull);
    });
  });

  group('UzLocalPhoneFormatter', () {
    String format(String input) {
      const formatter = UzLocalPhoneFormatter();
      return formatter
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: input),
          )
          .text;
    }

    test('groups the national digits as 2-3-2-2', () {
      expect(format('901234567'), '90 123 45 67');
      expect(format('9012'), '90 12');
    });

    test('caps at nine digits', () {
      expect(format('9012345678899'), '90 123 45 67');
    });

    test('strips a pasted country code and trunk zero', () {
      expect(format('+998 90 123 45 67'), '90 123 45 67');
      expect(format('998901234567'), '90 123 45 67');
      expect(format('0901234567'), '90 123 45 67');
    });
  });

  testWidgets('Phone sign-in page shows the phone stage first', (tester) async {
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
          home: const PhoneSignInPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in with phone'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
  });
}
