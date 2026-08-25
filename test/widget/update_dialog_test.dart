import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/features/dashboard/presentation/widgets/update_dialog.dart';

void main() {
  testWidgets(
    'UpdateDialog renders release notes in Markdown and displays update info',
    (WidgetTester tester) async {
      final updateInfo = {
        'latest_version': '1.2.0',
        'download_url': 'https://example.com/app.apk',
        'release_notes':
            '### What\'s New\n- **Feature 1**: Dynamic updates\n- **Fix**: Resolved UI bug',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: UpdateDialog(updateInfo: updateInfo)),
          ),
        ),
      );

      // Verify version badge and title
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('v1.2.0'), findsOneWidget);

      // Verify Markdown content
      expect(find.text("What's New"), findsWidgets);
      expect(
        find.textContaining('Feature 1', skipOffstage: false),
        findsWidgets,
      );
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    },
  );
}
