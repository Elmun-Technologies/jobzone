import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/design_system/design_system.dart';

void main() {
  testWidgets('JzErrorState shows message and fires onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: JzErrorState(
            title: 'Oops',
            message: 'Could not load',
            retryLabel: 'Retry',
            onRetry: () => retried++,
          ),
        ),
      ),
    );

    expect(find.text('Oops'), findsOneWidget);
    expect(find.text('Could not load'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('JzErrorState without onRetry hides the retry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: JzErrorState(message: 'No retry here')),
      ),
    );
    expect(find.text('No retry here'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
