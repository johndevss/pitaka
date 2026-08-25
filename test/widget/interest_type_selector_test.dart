import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/core/widgets/interest_type_selector.dart';

void main() {
  testWidgets(
    'InterestTypeSelector renders daily, monthly, yearly chips and handles selection',
    (tester) async {
      String selected = 'monthly';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return InterestTypeSelector(
                  selectedType: selected,
                  onChanged: (newType) {
                    setState(() {
                      selected = newType;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      await tester.tap(find.text('Daily'));
      await tester.pump();

      expect(selected, equals('daily'));
    },
  );
}
