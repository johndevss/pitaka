import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/models/account.dart';

void main() {
  test('Account.copyWith preserves unaltered fields', () {
    final account = Account(
      id: 1,
      name: 'Main GCash',
      type: 'e-wallet',
      provider: 'GCash',
      balance: 1000.0,
      currency: 'PHP',
      interestType: 'none',
      createdAt: DateTime(2026, 5, 1),
    );

    final updated = account.copyWith(balance: 1500.0);

    expect(updated.id, equals(1));
    expect(updated.name, equals('Main GCash'));
    expect(updated.balance, equals(1500.0));
    expect(updated.currency, equals('PHP'));
  });

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
