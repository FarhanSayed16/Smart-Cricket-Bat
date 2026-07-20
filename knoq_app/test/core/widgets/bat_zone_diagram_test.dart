import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/core/widgets/bat_zone_diagram.dart';


void main() {
  group('BatZoneDiagram', () {
    testWidgets('renders correctly without active zone', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatZoneDiagram(zoneDistribution: {}),
          ),
        ),
      );

      // We just ensure it builds and doesn't crash, because it's a CustomPaint
      expect(find.byType(BatZoneDiagram), findsOneWidget);
    });

    testWidgets('renders with active zone', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BatZoneDiagram(
              activeZone: 'Sweet',
              zoneDistribution: {'Sweet': 5, 'Top': 2},
            ),
          ),
        ),
      );

      expect(find.byType(BatZoneDiagram), findsOneWidget);
    });
  });
}
