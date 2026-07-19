import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/models/account.dart';

void main() {
  test('Account.toMap preserves the selected institution currency', () {
    final account = Account(
      name: 'ShopeePay',
      type: 'e-wallet',
      provider: 'shopeepay',
      balance: 123.45,
      currency: 'USD',
      interestType: 'none',
      createdAt: DateTime(2026, 7, 19),
    );

    final map = account.toMap();

    expect(map['currency'], equals('USD'));
  });
}
