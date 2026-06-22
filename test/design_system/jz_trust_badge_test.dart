import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/design_system/design_system.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );

  testWidgets('renders an icon-only badge for each trust kind', (tester) async {
    for (final kind in JzTrustKind.values) {
      await tester.pumpWidget(host(JzTrustBadge(kind: kind)));
      expect(find.byType(Icon), findsOneWidget);
    }
  });

  testWidgets('renders a labeled pill when a label is given', (tester) async {
    await tester.pumpWidget(
      host(const JzTrustBadge(kind: JzTrustKind.worker, label: 'Verified')),
    );
    expect(find.text('Verified'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });
}
