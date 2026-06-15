import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/design_system/design_system.dart';

void main() {
  testWidgets('JzSvgAsset builds an SvgPicture for the given asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JzSvgAsset(
            'assets/illustrations/placeholder.svg',
            width: 48,
            height: 48,
            semanticLabel: 'placeholder',
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
