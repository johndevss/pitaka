import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/core/utils/haptic_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'HapticEngine triggers haptic feedback methods without throwing exceptions',
    () async {
      await expectLater(HapticEngine.selection(), completes);
      await expectLater(HapticEngine.light(), completes);
      await expectLater(HapticEngine.medium(), completes);
      await expectLater(HapticEngine.heavy(), completes);
      await expectLater(HapticEngine.success(), completes);
    },
  );
}
