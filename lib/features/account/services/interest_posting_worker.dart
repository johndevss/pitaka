// lib/features/account/services/interest_posting_worker.dart

import 'package:sqflite/sqflite.dart';
import 'package:pitaka/core/database/database_helper.dart';
import 'package:pitaka/features/account/data/account_dao.dart';
import 'package:pitaka/features/account/data/interest_ledger_dao.dart';
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/account/models/account_interest_config.dart';
import 'package:pitaka/features/account/services/interest_engine.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';

class InterestPostingWorker {
  final AccountDao _accountDao;
  final InterestLedgerDao _ledgerDao;

  InterestPostingWorker({AccountDao? accountDao, InterestLedgerDao? ledgerDao})
    : _accountDao = accountDao ?? AccountDao(),
      _ledgerDao = ledgerDao ?? InterestLedgerDao();

  /// Executes interest accrual and posting check for all interest-earning accounts.
  Future<void> processAllAccounts({DateTime? overrideNow}) async {
    final db = await DatabaseHelper.initDb();
    final now = overrideNow ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final accounts = await _accountDao.getAllAccounts();
    for (final account in accounts) {
      if (account.id == null ||
          account.interestRate == null ||
          account.interestRate! <= 0) {
        continue;
      }
      await processAccountInterest(account, todayDate, db);
    }
  }

  /// Processes daily accrual and posting for a single account
  Future<void> processAccountInterest(
    Account account,
    DateTime todayDate, [
    DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await DatabaseHelper.initDb();

    // 1. Fetch interest config row
    final configRows = await db.query(
      'account_interest_configs',
      where: 'account_id = ?',
      whereArgs: [account.id],
    );
    if (configRows.isEmpty) return;
    final config = AccountInterestConfig.fromMap(configRows.first);

    // Determine start date for calculation
    DateTime startDate;
    if (config.lastInterestAppliedDate != null &&
        config.lastInterestAppliedDate!.isNotEmpty) {
      final lastDate = DateTime.parse(config.lastInterestAppliedDate!);
      startDate = lastDate.add(const Duration(days: 1));
    } else {
      startDate = DateTime(
        account.createdAt.year,
        account.createdAt.month,
        account.createdAt.day,
      );
    }

    // Yesterday is the last full day for accrual calculation
    final yesterday = todayDate.subtract(const Duration(days: 1));
    if (startDate.isAfter(yesterday)) return; // Up to date

    final currentBalance = account.balance;

    // 2. Calculate missed days
    final dailyResults = InterestEngine.calculateMissedDays(
      account: account,
      config: config,
      startDate: startDate,
      endDate: yesterday,
      runningBalance: currentBalance,
    );

    if (dailyResults.isEmpty) return;

    // 3. Batch insert daily interest logs into interest_ledger
    final ledgerMaps = <Map<String, dynamic>>[];
    DateTime curDate = startDate;
    for (final res in dailyResults) {
      final isoDate = curDate.toIso8601String().split('T').first;
      ledgerMaps.add(res.toMap(account.id!, isoDate));
      curDate = curDate.add(const Duration(days: 1));
    }

    await _ledgerDao.insertBatchLedgerLogs(ledgerMaps, db);

    // 4. Check if posting threshold is reached (daily or monthly)
    final unpostedLogs = await _ledgerDao.getUnpostedLogsForAccount(
      account.id!,
      db,
    );
    if (unpostedLogs.isEmpty) return;

    final shouldPost =
        config.payoutFrequency == 'daily' ||
        (config.payoutFrequency == 'monthly' &&
            todayDate.day >= config.payoutDay);

    if (shouldPost && config.autoPost) {
      double totalGross = 0.0;
      double totalTax = 0.0;
      double totalNet = 0.0;
      final logIds = <int>[];

      for (final log in unpostedLogs) {
        logIds.add(log['id'] as int);
        totalGross += (log['gross_interest'] as num).toDouble();
        totalTax += (log['tax_deducted'] as num).toDouble();
        totalNet += (log['net_interest'] as num).toDouble();
      }

      if (totalNet > 0) {
        // Fetch or identify Interest Income system category
        final catRows = await db.query(
          'categories',
          where: "name = 'Interest Income' OR name = 'Interest'",
          limit: 1,
        );
        final int? categoryId = catRows.isNotEmpty
            ? catRows.first['id'] as int?
            : null;

        // Create transaction entry
        final tx = TransactionModel(
          accountId: account.id!,
          type: 'interest',
          amount: totalNet,
          categoryId: categoryId,
          grossAmount: totalGross,
          taxAmount: totalTax,
          note: config.payoutFrequency == 'daily'
              ? 'Daily Interest Credit'
              : 'Monthly Interest Credit',
          transactionDate: todayDate,
          createdAt: DateTime.now(),
        );

        await db.insert(
          'transactions',
          tx.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Mark ledger entries as posted
        await _ledgerDao.markLogsAsPosted(logIds, db);

        // Update last_interest_applied_date
        final lastAppliedIso = yesterday.toIso8601String().split('T').first;
        await db.update(
          'account_interest_configs',
          {'last_interest_applied_date': lastAppliedIso},
          where: 'account_id = ?',
          whereArgs: [account.id],
        );
      }
    }
  }
}
