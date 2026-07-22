import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pitaka/data/account_dao.dart';
import 'package:pitaka/data/database_helper.dart';
import 'package:pitaka/data/transaction_dao.dart';
import 'package:pitaka/models/account.dart';
import 'package:pitaka/models/transaction_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await DatabaseHelper.initDb();
    await db.delete('transactions');
    await db.delete('accounts');
  });

  final dao = AccountDao();
  final txDao = TransactionDao();

  Account buildAccount({String name = 'Test GCash', double balance = 1000.0}) {
    return Account(
      name: name,
      type: 'e-wallet',
      provider: 'GCash',
      balance: balance,
      currency: 'PHP',
      interestType: 'none',
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('insertAccount then getAccountById returns the same account', () async {
    final id = await dao.insertAccount(buildAccount());
    final result = await dao.getAccountById(id);

    expect(result, isNotNull);
    expect(result!.name, equals('Test GCash'));
    expect(result.balance, equals(1000.0));
  });

  test('getAllAccounts returns accounts ordered by created_at DESC', () async {
    await dao.insertAccount(
      buildAccount(name: 'Older').copyWith(createdAt: DateTime(2026, 1, 1)),
    );
    await dao.insertAccount(
      buildAccount(name: 'Newer').copyWith(createdAt: DateTime(2026, 6, 1)),
    );

    final all = await dao.getAllAccounts();

    expect(all.length, equals(2));
    expect(all.first.name, equals('Newer'));
  });

  test('updateAccount persists field changes', () async {
    final id = await dao.insertAccount(buildAccount());
    final original = await dao.getAccountById(id);

    final updated = original!.copyWith(name: 'Renamed Wallet');
    await dao.updateAccount(updated);

    final result = await dao.getAccountById(id);
    expect(result!.name, equals('Renamed Wallet'));
  });

  test('deleteAccount removes the account', () async {
    final id = await dao.insertAccount(buildAccount());
    await dao.deleteAccount(id);

    final result = await dao.getAccountById(id);
    expect(result, isNull);
  });

  group('getCurrentBalance', () {
    test('equals starting balance when there are no transactions', () async {
      final id = await dao.insertAccount(buildAccount(balance: 500.0));

      final balance = await dao.getCurrentBalance(id);

      expect(balance, equals(500.0));
    });

    test('sums correctly with multiple transactions', () async {
      final id = await dao.insertAccount(buildAccount(balance: 500.0));

      await txDao.insertTransaction(
        TransactionModel(
          accountId: id,
          amount: -250.50,
          category: 'Food',
          createdAt: DateTime(2026, 1, 2),
        ),
      );
      await txDao.insertTransaction(
        TransactionModel(
          accountId: id,
          amount: 1000.0,
          category: 'Salary',
          createdAt: DateTime(2026, 1, 3),
        ),
      );

      final balance = await dao.getCurrentBalance(id);

      // 500 (starting) - 250.50 + 1000 = 1249.50
      expect(balance, equals(1249.50));
    });

    test('returns 0.0 for a non-existent account', () async {
      final balance = await dao.getCurrentBalance(9999);
      expect(balance, equals(0.0));
    });
  });
}
