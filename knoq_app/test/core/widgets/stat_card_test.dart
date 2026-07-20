import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/core/widgets/stat_card.dart';

void main() {
  group('StatCard', () {
    testWidgets('renders label, value, and icon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Total Hits',
              value: '150',
              icon: Icons.sports_cricket,
            ),
          ),
        ),
      );

      expect(find.text('Total Hits'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.byIcon(Icons.sports_cricket), findsOneWidget);
    });

    testWidgets('renders trend arrow if provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Avg Power',
              value: '85%',
              icon: Icons.bolt,
              trendLabel: '+5.0%',
              isTrendPositive: true,
            ),
          ),
        ),
      );

      expect(find.text('Avg Power'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('+5.0%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });
  });
}
