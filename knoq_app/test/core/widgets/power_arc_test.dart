import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/core/widgets/power_arc.dart';

void main() {
  group('PowerArc', () {
    testWidgets('renders correctly and displays value and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PowerArc(
              value: 75,
              label: 'Avg Power',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the label is displayed
      expect(find.text('Avg Power'), findsOneWidget);
      
      // Verify that the value is displayed
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('respects missing label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PowerArc(
              value: 50,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the value is displayed
      expect(find.text('50'), findsOneWidget);
    });
  });
}
