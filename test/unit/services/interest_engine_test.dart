// test/unit/services/interest_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pitaka/core/database/database_helper.dart';
import 'package:pitaka/features/account/data/account_dao.dart';
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/account/models/account_interest_config.dart';
import 'package:pitaka/features/account/services/interest_engine.dart';
import 'package:pitaka/features/account/services/interest_posting_worker.dart';
import 'package:pitaka/features/transaction/data/transaction_dao.dart';

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
    await db.delete('interest_ledger');
    await db.delete('transactions');
    await db.delete('account_interest_configs');
    await db.delete('accounts');
  });

  group('InterestEngine Calculations', () {
    test(
      'calculateDailyInterest computes 20% WHT correctly for SeaBank (4.5%)',
      () {
        // ₱100,000 balance at 4.5% annual rate
        // Gross daily = 100,000 * 0.045 / 365 = 12.328767
        // WHT 20% = 2.465753
        // Net = 9.863013
        final result = InterestEngine.calculateDailyInterest(
          closingBalance: 100000.0,
          annualRate: 0.045,
          withholdingTaxRate: 0.20,
        );

        expect(result.grossInterest, closeTo(12.3287, 0.001));
        expect(result.taxDeducted, closeTo(2.4657, 0.001));
        expect(result.netInterest, closeTo(9.8630, 0.001));
      },
    );

    test(
      'calculateDailyInterest computes Tiered interest for DiskarTech (6.5% cap 50k, 3% excess)',
      () {
        // ₱75,000 balance
        // Tier 1 (50,000 @ 6.5%): 50,000 * 0.065 / 365 = 8.9041
        // Tier 2 (25,000 @ 3.0%): 25,000 * 0.030 / 365 = 2.0547
        // Total Gross = 10.9589
        // Tax (20%) = 2.1917
        // Net = 8.7671
        final result = InterestEngine.calculateDailyInterest(
          closingBalance: 75000.0,
          annualRate: 0.065,
          withholdingTaxRate: 0.20,
          tierCapAmount: 50000.0,
          secondaryInterestRate: 0.030,
        );

        expect(result.grossInterest, closeTo(10.9589, 0.001));
        expect(result.taxDeducted, closeTo(2.1917, 0.001));
        expect(result.netInterest, closeTo(8.7671, 0.001));
      },
    );

    test('calculateMissedDays generates correct number of daily entries', () {
      final account = Account(
        id: 1,
        name: 'Test SeaBank',
        currency: 'PHP',
        createdAt: DateTime(2026, 1, 1),
      );
      final config = AccountInterestConfig(accountId: 1, interestRate: 0.045);

      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 5); // 5 days: 1st, 2nd, 3rd, 4th, 5th

      final missed = InterestEngine.calculateMissedDays(
        account: account,
        config: config,
        startDate: startDate,
        endDate: endDate,
        runningBalance: 50000.0,
      );

      expect(missed.length, equals(5));
      for (final day in missed) {
        expect(day.grossInterest, greaterThan(0));
      }
    });
  });

  group('InterestPostingWorker Integration', () {
    test(
      'processAllAccounts calculates missed daily interest and posts payout transaction',
      () async {
        final accountDao = AccountDao();
        final txDao = TransactionDao();
        final worker = InterestPostingWorker();

        // Create SeaBank account with 4.5% interest starting 5 days ago
        final createdDate = DateTime(2026, 8, 18);
        final account = Account(
          name: 'My SeaBank',
          institutionId: 'seabank',
          accountType: 'bank',
          initialBalance: 100000.0,
          currency: 'PHP',
          createdAt: createdDate,
        );
        final config = AccountInterestConfig(
          accountId: 0,
          interestRate: 0.045,
          calcMode: 'daily_payout',
          payoutFrequency: 'daily',
        );

        final accountId = await accountDao.insertAccountWithConfig(
          account,
          config,
        );

        // Run worker with today as 2026-08-23
        final todayDate = DateTime(2026, 8, 23);
        await worker.processAllAccounts(overrideNow: todayDate);

        // Check transactions created
        final txs = await txDao.getTransactionsByAccount(accountId);
        expect(txs.isNotEmpty, isTrue);

        // Verify transaction attributes
        final interestTx = txs.first;
        expect(interestTx.type, equals('interest'));
        expect(interestTx.amount, greaterThan(0));

        // Verify updated account balance includes posted interest
        final updatedAccount = await accountDao.getAccountById(accountId);
        expect(updatedAccount, isNotNull);
        expect(updatedAccount!.balance, greaterThan(100000.0));
      },
    );
  });
}
