import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/models/daily_limit.dart';

void main() {
  test('DailyLimit converting to and from Map', () {
    final effectiveDate = DateTime(2026, 5, 1);
    final limit = DailyLimit(
      id: 1,
      amount: 500.0,
      effectiveDate: effectiveDate,
    );

    final map = limit.toMap();
    expect(map['amount'], equals(500.0));
    expect(map['effective_date'], equals(effectiveDate.toIso8601String()));

    final restored = DailyLimit.fromMap(map);
    expect(restored.amount, equals(500.0));
  });
}
