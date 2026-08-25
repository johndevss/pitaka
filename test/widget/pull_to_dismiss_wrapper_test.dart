import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/core/widgets/pull_to_dismiss_wrapper.dart';

void main() {
  testWidgets('PullToDismissWrapper renders drag handle and child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PullToDismissWrapper(child: Text('Modal Content')),
        ),
      ),
    );

    expect(find.text('Modal Content'), findsOneWidget);
  });

  testWidgets(
    'PullToDismissWrapper triggers onDismissed when dragged past threshold',
    (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PullToDismissWrapper(
              onDismissed: () {
                dismissed = true;
              },
              child: const SizedBox(
                width: 300,
                height: 400,
                child: Text('Drag Me'),
              ),
            ),
          ),
        ),
      );

      // Drag down by 200px
      await tester.drag(find.text('Drag Me'), const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    },
  );
}
