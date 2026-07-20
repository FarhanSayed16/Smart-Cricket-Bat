import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/core/widgets/zone_badge.dart';

void main() {
  group('ZoneBadge', () {
    testWidgets('renders correctly and displays zone text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZoneBadge(zone: 'Sweet'),
          ),
        ),
      );

      expect(find.text('Sweet'), findsOneWidget);
    });

    testWidgets('displays Unknown if zone is unrecognized', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZoneBadge(zone: 'InvalidZone'),
          ),
        ),
      );

      expect(find.text('InvalidZone'), findsOneWidget);
    });
  });
}
