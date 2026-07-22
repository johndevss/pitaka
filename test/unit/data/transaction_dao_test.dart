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

  final dao = TransactionDao();
  final accountDao = AccountDao();

  Future<int> seedAccount() {
    return accountDao.insertAccount(
      Account(
        name: 'Seed Account',
        type: 'e-wallet',
        provider: 'GCash',
        balance: 0,
        currency: 'PHP',
        interestType: 'none',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  test('insertTransaction then getAllTransactions returns it', () async {
    final accountId = await seedAccount();
    await dao.insertTransaction(
      TransactionModel(
        accountId: accountId,
        amount: -100.0,
        category: 'Transport',
        createdAt: DateTime(2026, 1, 5),
      ),
    );

    final all = await dao.getAllTransactions();

    expect(all.length, equals(1));
    expect(all.first.category, equals('Transport'));
  });

  test('getTransactionsByAccount only returns matching account', () async {
    final accountA = await seedAccount();
    final accountB = await seedAccount();

    await dao.insertTransaction(
      TransactionModel(
        accountId: accountA,
        amount: -50.0,
        createdAt: DateTime(2026, 1, 5),
      ),
    );
    await dao.insertTransaction(
      TransactionModel(
        accountId: accountB,
        amount: -75.0,
        createdAt: DateTime(2026, 1, 5),
      ),
    );

    final results = await dao.getTransactionsByAccount(accountA);

    expect(results.length, equals(1));
    expect(results.first.amount, equals(-50.0));
  });

  test('getTodayTransactions excludes transactions from other days', () async {
    final accountId = await seedAccount();
    final now = DateTime.now();

    await dao.insertTransaction(
      TransactionModel(
        accountId: accountId,
        amount: -20.0,
        createdAt: now, // today
      ),
    );
    await dao.insertTransaction(
      TransactionModel(
        accountId: accountId,
        amount: -30.0,
        createdAt: now.subtract(const Duration(days: 3)), // not today
      ),
    );

    final todays = await dao.getTodayTransactions();

    expect(todays.length, equals(1));
    expect(todays.first.amount, equals(-20.0));
  });

  test('updateTransaction persists changes', () async {
    final accountId = await seedAccount();
    await dao.insertTransaction(
      TransactionModel(
        accountId: accountId,
        amount: -20.0,
        createdAt: DateTime(2026, 1, 5),
      ),
    );

    final all = await dao.getAllTransactions();
    final updated = all.first.copyWith(amount: -999.0);
    await dao.updateTransaction(updated);

    final result = await dao.getAllTransactions();
    expect(result.first.amount, equals(-999.0));
  });

  test('deleteTransaction removes it', () async {
    final accountId = await seedAccount();
    final id = await dao.insertTransaction(
      TransactionModel(
        accountId: accountId,
        amount: -20.0,
        createdAt: DateTime(2026, 1, 5),
      ),
    );

    await dao.deleteTransaction(id);

    final all = await dao.getAllTransactions();
    expect(all, isEmpty);
  });
}
