// lib/data/account_dao.dart

import 'package:sqflite/sqflite.dart';
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/core/database/database_helper.dart';

class AccountDao {
  // CREATE — inserts a new account, returns the generated id
  Future<int> insertAccount(Account account) async {
    final db = await DatabaseHelper.initDb();
    return await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ — get all accounts
  Future<List<Account>> getAllAccounts() async {
    final db = await DatabaseHelper.initDb();
    final result = await db.query('accounts', orderBy: 'created_at DESC');

    return result.map((map) => Account.fromMap(map)).toList();
  }

  // READ — get a single account by id
  Future<Account?> getAccountById(int id, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.initDb();
    final result = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Account.fromMap(result.first);
  }

  // UPDATE — updates an existing account (must have an id)
  Future<int> updateAccount(Account account) async {
    final db = await DatabaseHelper.initDb();
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // DELETE
  Future<int> deleteAccount(int id) async {
    final db = await DatabaseHelper.initDb();
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Method to calculate the current balance of an account by summing its transactions
  Future<double> getCurrentBalance(
    int accountId, [
    DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await DatabaseHelper.initDb();

    final result = await db.rawQuery(
      '''
      SELECT (a.balance + COALESCE(SUM(t.amount), 0)) as current_balance
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

  // Aggregated total equity grouped by currency in a single high-performance SQL query
  Future<Map<String, double>> getTotalEquityByCurrency() async {
    final db = await DatabaseHelper.initDb();
    final result = await db.rawQuery('''
      SELECT a.currency, SUM(a.balance + COALESCE(t.total_tx, 0)) as total
      FROM accounts a
      LEFT JOIN (
        SELECT account_id, SUM(amount) as total_tx
        FROM transactions
        GROUP BY account_id
      ) t ON a.id = t.account_id
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
