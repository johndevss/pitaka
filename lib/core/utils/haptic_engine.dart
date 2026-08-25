// lib/core/utils/haptic_engine.dart

import 'package:flutter/services.dart';

/// Semantic haptic feedback wrapper providing consistent tactile feedback
/// across key app interactions.
class HapticEngine {
  HapticEngine._();

  /// Selection tick (tab switching, item toggles).
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Light impact (keypad presses, chip selections).
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact (menu expansion, modal triggers).
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact (long-press shortcuts, destructive actions).
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Double-tick haptic pattern on successful transaction save.
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
}
