import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/design_system/design_system.dart';
import 'package:jobzone/features/profile/domain/user_profile.dart';
import 'package:jobzone/features/profile/presentation/widgets/worker_card.dart';
import 'package:jobzone/localization/generated/app_localizations.dart';

void main() {
  testWidgets('WorkerCard shows name, UZS pay and a verify-phone CTA', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: WorkerCard(
            profile: const UserProfile(
              fullName: 'Aziz',
              workerVerified: true,
              desiredPayMin: 4000000,
              desiredPayMax: 7000000,
              availability: 'immediate',
            ),
            skills: const ['Forklift', 'Driving'],
            onVerifyPhone: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Aziz'), findsOneWidget);
    expect(find.textContaining("so'm"), findsWidgets);

    await tester.tap(find.text('Verify phone'));
    expect(tapped, isTrue);
  });
}
