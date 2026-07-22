import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/models/transaction_model.dart';

void main() {
  test('TransactionModel converting to and from Map', () {
    final now = DateTime(2026, 5, 20);
    final transaction = TransactionModel(
      id: 1,
      accountId: 10,
      amount: -250.50,
      category: 'Food',
      note: 'Lunch at Jollibee',
      createdAt: now,
    );

    final map = transaction.toMap();
    expect(map['account_id'], equals(10));
    expect(map['amount'], equals(-250.50));
    expect(map['category'], equals('Food'));

    final restored = TransactionModel.fromMap(map);
    expect(restored.id, equals(1));
    expect(restored.amount, equals(-250.50));
    expect(restored.note, equals('Lunch at Jollibee'));
  });
}
