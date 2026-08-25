import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/core/widgets/floating_nav_bar.dart';
import 'package:pitaka/features/dashboard/presentation/home_shell.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('HomeShell updates tab on tap and allows swiping', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderScope(child: HomeShell())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Wallet tab
    await tester.tap(find.text('Wallet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    var navBar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(navBar.selectedTab, equals(NavTab.wallet));

    // Fling right-to-left on PageView to navigate to Manage tab
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    navBar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(navBar.selectedTab, equals(NavTab.manage));
  });
}
