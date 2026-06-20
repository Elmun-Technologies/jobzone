import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobzone/design_system/design_system.dart';
import 'package:jobzone/features/monetization/domain/promotion.dart';
import 'package:jobzone/features/monetization/presentation/widgets/promo_package_card.dart';
import 'package:jobzone/localization/generated/app_localizations.dart';

void main() {
  testWidgets('PromoPackageCard shows name and UZS price', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PromoPackageCard(
            product: const PromotionProduct(
              code: 'top_3',
              name: '3 kun TOP',
              description: 'Top for 3 days',
              kind: 'top',
              priceUzs: 15000,
              durationDays: 3,
            ),
            selected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('3 kun TOP'), findsOneWidget);
    expect(find.text("15 000 so'm"), findsOneWidget);
  });
}
