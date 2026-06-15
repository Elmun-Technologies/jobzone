import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzone/design_system/design_system.dart';

void main() {
  testWidgets('JobListSkeleton renders N shimmering card placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: JobListSkeleton(count: 3)),
      ),
    );
    // One animation frame (the shimmer repeats forever, so don't settle).
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(JobCardSkeleton), findsNWidgets(3));
    expect(find.byType(Shimmer), findsOneWidget);
  });

  testWidgets('Shimmer disposes its controller without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Shimmer(child: SkeletonBox(width: 100, height: 20)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // Replacing the tree triggers Shimmer.dispose(); must not throw.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
