import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/main.dart';
import 'package:pitaka/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('Pitaka App smoke test - layout renders successfully', (WidgetTester tester) async {
    // Build app with ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: PitakaApp(),
      ),
    );

    // Verify FloatingNavBar exists
    expect(find.byType(FloatingNavBar), findsOneWidget);

    // Verify navigation tabs render
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Verify add button icon renders
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}