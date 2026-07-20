import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knoq_app/core/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title and subtitle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No Data',
              subtitle: 'There is no data to display.',
              illustration: const Icon(Icons.inbox),
            ),
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('There is no data to display.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      
      // No button should be present
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders CTA button if provided', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No Data',
              subtitle: 'There is no data to display.',
              illustration: const Icon(Icons.inbox),
              buttonText: 'Refresh',
              onButtonPress: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Refresh'), findsOneWidget);
      
      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(buttonPressed, true);
    });
  });
}
