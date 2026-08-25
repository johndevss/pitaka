import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/core/widgets/numeric_keypad.dart';

void main() {
  testWidgets('NumericKeypad renders digits and triggers onKeyTap', (
    tester,
  ) async {
    String pressedKey = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onKeyTap: (key) {
              pressedKey = key;
            },
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('.'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

    await tester.tap(find.text('7'));
    await tester.pump();

    expect(pressedKey, equals('7'));

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(pressedKey, equals('backspace'));
  });
}
