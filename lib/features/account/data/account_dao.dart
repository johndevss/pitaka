// lib/features/account/data/account_dao.dart

import 'package:sqflite/sqflite.dart';
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/account/models/account_interest_config.dart';
import 'package:pitaka/core/database/database_helper.dart';

class AccountDao {
  // CREATE — inserts a new account, returns generated id
  Future<int> insertAccount(Account account) async {
    final db = await DatabaseHelper.initDb();
    return await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // CREATE WITH CONFIG — atomic transaction for account and interest config
  Future<int> insertAccountWithConfig(
    Account account,
    AccountInterestConfig? config,
  ) async {
    final db = await DatabaseHelper.initDb();
    return await db.transaction((txn) async {
      final accountId = await txn.insert(
        'accounts',
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (config != null) {
        final configMap = config.toMap()..['account_id'] = accountId;
        await txn.insert(
          'account_interest_configs',
          configMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return accountId;
    });
  }

  // READ — get all active accounts with joined balances, interest configs, and accrued ledger
  Future<List<Account>> getAllAccounts() async {
    final db = await DatabaseHelper.initDb();
    final result = await db.rawQuery('''
      SELECT 
        a.*,
        aic.interest_rate,
        aic.calc_mode,
        aic.payout_frequency,
        (COALESCE(a.initial_balance, a.balance) + COALESCE(tx.net_tx, 0)) AS current_balance,
        COALESCE(il.pending_accrued_interest, 0.0) AS pending_interest
      FROM accounts a
      LEFT JOIN account_interest_configs aic ON a.id = aic.account_id
      LEFT JOIN (
        SELECT account_id, SUM(amount) AS net_tx
        FROM transactions
        GROUP BY account_id
      ) tx ON a.id = tx.account_id
      LEFT JOIN (
        SELECT account_id, SUM(net_interest) AS pending_accrued_interest
        FROM interest_ledger
        WHERE is_posted = 0
        GROUP BY account_id
      ) il ON a.id = il.account_id
      WHERE a.is_archived = 0
      ORDER BY a.created_at DESC
    ''');

    return result.map((map) => Account.fromMap(map)).toList();
  }

  // READ — get a single account by id with joined balance and config
  Future<Account?> getAccountById(int id, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.initDb();
    final result = await db.rawQuery(
      '''
      SELECT 
        a.*,
        aic.interest_rate,
        aic.calc_mode,
        aic.payout_frequency,
        (COALESCE(a.initial_balance, a.balance) + COALESCE(tx.net_tx, 0)) AS current_balance,
        COALESCE(il.pending_accrued_interest, 0.0) AS pending_interest
      FROM accounts a
      LEFT JOIN account_interest_configs aic ON a.id = aic.account_id
      LEFT JOIN (
        SELECT account_id, SUM(amount) AS net_tx
        FROM transactions
        WHERE account_id = ?
      ) tx ON a.id = tx.account_id
      LEFT JOIN (
        SELECT account_id, SUM(net_interest) AS pending_accrued_interest
        FROM interest_ledger
        WHERE account_id = ? AND is_posted = 0
      ) il ON a.id = il.account_id
      WHERE a.id = ?
    ''',
      [id, id, id],
    );

    if (result.isEmpty || result.first['id'] == null) return null;
    return Account.fromMap(result.first);
  }

  // UPDATE — updates an existing account
  Future<int> updateAccount(Account account) async {
    final db = await DatabaseHelper.initDb();
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Updates an account and its interest configuration atomically.
  Future<void> updateAccountWithConfig(
    Account account,
    AccountInterestConfig? config,
  ) async {
    final db = await DatabaseHelper.initDb();
    await db.transaction((txn) async {
      await txn.update(
        'accounts',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );

      if (config != null) {
        final configMap = config.toMap()..['account_id'] = account.id;
        await txn.insert(
          'account_interest_configs',
          configMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else if (account.id != null) {
        await txn.delete(
          'account_interest_configs',
          where: 'account_id = ?',
          whereArgs: [account.id],
        );
      }
    });
  }

  // DELETE
  Future<int> deleteAccount(int id) async {
    final db = await DatabaseHelper.initDb();
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Calculate current balance of an account
  Future<double> getCurrentBalance(
    int accountId, [
    DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await DatabaseHelper.initDb();
    final result = await db.rawQuery(
      '''
      SELECT (COALESCE(a.initial_balance, a.balance) + COALESCE(SUM(t.amount), 0)) as current_balance
      FROM accounts a
      LEFT JOIN transactions t ON a.id = t.account_id
      WHERE a.id = ?
      GROUP BY a.id
    ''',
      [accountId],
    );

    if (result.isEmpty) return 0.0;
    return (result.first['current_balance'] as num?)?.toDouble() ?? 0.0;
  }

  // Aggregated total equity grouped by currency
  Future<Map<String, double>> getTotalEquityByCurrency() async {
    final db = await DatabaseHelper.initDb();
    final result = await db.rawQuery('''
      SELECT a.currency, SUM(COALESCE(a.initial_balance, a.balance) + COALESCE(t.total_tx, 0)) as total
      FROM accounts a
      LEFT JOIN (
        SELECT account_id, SUM(amount) as total_tx
        FROM transactions
        GROUP BY account_id
      ) t ON a.id = t.account_id
      WHERE a.is_archived = 0
      GROUP BY a.currency
    ''');

    final Map<String, double> totals = {};
    for (final row in result) {
      final currency = row['currency'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      totals[currency] = total;
    }
    return totals;
  }
}
