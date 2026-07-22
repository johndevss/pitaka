import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('FloatingNavBar toggles icon to close when menu is open', (WidgetTester tester) async {
    bool isMenuOpen = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FloatingNavBar(
                selectedTab: NavTab.home,
                isMenuOpen: isMenuOpen,
                onTabSelected: (_) {},
                onAddPressed: () {
                  setState(() => isMenuOpen = !isMenuOpen);
                },
              ),
            ),
          );
        },
      ),
    );

    // Initial state: shows '+' icon
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    // Tap the add button
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // Menu open state: shows 'X' icon
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });
}