// Smoke test for the Inventory Counting app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_counting/main.dart';
import 'package:inventory_counting/theme/tokens.dart';
import 'package:inventory_counting/screens/new_count_screen.dart';

void main() {
  testWidgets('App starts on login, sample-data path opens dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const InventoryCountingApp());
    await tester.pump();

    // Login is the entry point.
    expect(find.text('Sign In'), findsOneWidget);

    // The "continue with sample data" path lands on the dashboard.
    await tester.tap(find.text('Continue with sample data'));
    await tester.pumpAndSettle();
    expect(find.text('Inventory Counts'), findsOneWidget);
    expect(find.text('New Count'), findsOneWidget);
  });

  testWidgets('Create Count lays out without overflow on a phone', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: NewCountScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Full Count'), findsOneWidget);
    expect(find.text('Cycle Count'), findsOneWidget);
  });

  test('fmtNum uses Indian grouping', () {
    expect(fmtNum(1200), '1,200');
    expect(fmtNum(1234567), '12,34,567');
  });
}
