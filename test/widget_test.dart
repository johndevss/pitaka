import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/main.dart';
import 'package:pitaka/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('Pitaka App smoke test - layout renders successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PitakaApp());

    // Verify that the initial Home state text displays correctly
    expect(find.text('Current Screen: HOME'), findsOneWidget);

    // Verify that the FloatingNavBar component exists on screen
    expect(find.byType(FloatingNavBar), findsOneWidget);

    // Verify that the tab options exist within the layout
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Verify that our add button icon renders
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}