import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pitaka/core/database/database_helper.dart';
import 'package:pitaka/features/account/controllers/account_providers.dart';
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/transaction/controllers/transaction_providers.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: DatabaseHelper.onCreate,
      ),
    );
    DatabaseHelper.setDatabaseForTesting(db);
  });

  setUp(() async {
    final db = await DatabaseHelper.initDb();
    await db.delete('transactions');
    await db.delete('accounts');
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  Future<Account> seedAccount(
    ProviderContainer container, {
    double balance = 1000.0,
  }) async {
    final accController = container.read(accountsControllerProvider.notifier);
    await accController.addAccount(
      Account(
        name: 'Main Account',
        accountType: 'bank',
        institutionId: 'bpi',
        initialBalance: balance,
        currency: 'PHP',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    final accounts = await container.read(accountsControllerProvider.future);
    return accounts.first;
  }

  test('TransactionsController adds transaction successfully', () async {
    final container = makeContainer();
    final account = await seedAccount(container);
    final controller = container.read(transactionsControllerProvider.notifier);

    await controller.addTransaction(
      TransactionModel(
        accountId: account.id!,
        amount: -150.0,
        category: 'Food',
        createdAt: DateTime.now(),
      ),
    );

    final transactions = await container.read(
      transactionsControllerProvider.future,
    );
    expect(transactions.length, equals(1));
    expect(transactions.first.amount, equals(-150.0));
  });

  test(
    'TransactionsController performs atomic transfer successfully',
    () async {
      final container = makeContainer();
      final accController = container.read(accountsControllerProvider.notifier);

      await accController.addAccount(
        Account(
          name: 'Sender Account',
          accountType: 'bank',
          institutionId: 'bpi',
          initialBalance: 1000.0,
          currency: 'PHP',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await accController.addAccount(
        Account(
          name: 'Receiver Account',
          accountType: 'e-wallet',
          institutionId: 'gcash',
          initialBalance: 500.0,
          currency: 'PHP',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final accounts = await container.read(accountsControllerProvider.future);
      final sender = accounts.firstWhere((a) => a.name == 'Sender Account');
      final receiver = accounts.firstWhere((a) => a.name == 'Receiver Account');

      final now = DateTime.now();
      final expense = TransactionModel(
        accountId: sender.id!,
        amount: -300.0,
        category: 'Transfer Out',
        note: 'To Receiver',
        createdAt: now,
      );
      final income = TransactionModel(
        accountId: receiver.id!,
        amount: 300.0,
        category: 'Transfer In',
        note: 'From Sender',
        createdAt: now,
      );

      final controller = container.read(
        transactionsControllerProvider.notifier,
      );
      await controller.transfer(expense: expense, income: income);

      final txs = await container.read(transactionsControllerProvider.future);
      expect(txs.length, equals(2));

      final senderBal = await container.read(
        accountBalanceProvider(sender.id!).future,
      );
      final receiverBal = await container.read(
        accountBalanceProvider(receiver.id!).future,
      );

      expect(senderBal, equals(700.0));
      expect(receiverBal, equals(800.0));
    },
  );

  test('TransactionsController deletes transaction successfully', () async {
    final container = makeContainer();
    final account = await seedAccount(container);
    final controller = container.read(transactionsControllerProvider.notifier);

    await controller.addTransaction(
      TransactionModel(
        accountId: account.id!,
        amount: -50.0,
        category: 'Snacks',
        createdAt: DateTime.now(),
      ),
    );

    final initialList = await container.read(
      transactionsControllerProvider.future,
    );
    final txId = initialList.first.id!;

    await controller.deleteTransaction(txId, accountId: account.id!);

    final afterDelete = await container.read(
      transactionsControllerProvider.future,
    );
    expect(afterDelete, isEmpty);
  });
}
