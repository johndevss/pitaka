import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pitaka/core/database/database_helper.dart';
import 'package:pitaka/features/account/controllers/account_providers.dart';
import 'package:pitaka/features/account/models/account.dart';

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

  test('AccountsController adds account successfully', () async {
    final container = makeContainer();
    final controller = container.read(accountsControllerProvider.notifier);

    await controller.addAccount(
      Account(
        name: 'Test Wallet',
        type: 'e-wallet',
        provider: 'GCash',
        balance: 500.0,
        currency: 'PHP',
        interestType: 'none',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    final accounts = await container.read(accountsControllerProvider.future);
    expect(accounts.length, equals(1));
    expect(accounts.first.name, equals('Test Wallet'));
  });

  test('AccountsController updates account successfully', () async {
    final container = makeContainer();
    final controller = container.read(accountsControllerProvider.notifier);

    await controller.addAccount(
      Account(
        name: 'Initial Name',
        type: 'bank',
        provider: 'BPI',
        balance: 1000.0,
        currency: 'PHP',
        interestType: 'none',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    final initialList = await container.read(accountsControllerProvider.future);
    final account = initialList.first;

    await controller.updateAccount(account.copyWith(name: 'Updated BPI'));

    final updatedList = await container.read(accountsControllerProvider.future);
    expect(updatedList.first.name, equals('Updated BPI'));
  });

  test('AccountsController deletes account successfully', () async {
    final container = makeContainer();
    final controller = container.read(accountsControllerProvider.notifier);

    await controller.addAccount(
      Account(
        name: 'To Delete',
        type: 'cash',
        provider: 'Cash',
        balance: 200.0,
        currency: 'PHP',
        interestType: 'none',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    final initialList = await container.read(accountsControllerProvider.future);
    final id = initialList.first.id!;

    await controller.deleteAccount(id);

    final afterDelete = await container.read(accountsControllerProvider.future);
    expect(afterDelete, isEmpty);
  });
}
