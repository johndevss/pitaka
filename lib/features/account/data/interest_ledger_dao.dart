// lib/features/account/data/interest_ledger_dao.dart

import 'package:sqflite/sqflite.dart';
import 'package:pitaka/core/database/database_helper.dart';

class InterestLedgerDao {
  /// Inserts multiple daily ledger entries inside a single atomic SQLite transaction
  Future<void> insertBatchLedgerLogs(
    List<Map<String, dynamic>> logs, [
    DatabaseExecutor? executor,
  ]) async {
    if (logs.isEmpty) return;
    final db = executor ?? await DatabaseHelper.initDb();

    if (executor != null) {
      for (final log in logs) {
        await executor.insert(
          'interest_ledger',
          log,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } else {
      await (db as Database).transaction((txn) async {
        for (final log in logs) {
          await txn.insert(
            'interest_ledger',
            log,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
  }

  /// Returns all unposted ledger logs for a specific account
  Future<List<Map<String, dynamic>>> getUnpostedLogsForAccount(
    int accountId, [
    DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await DatabaseHelper.initDb();
    return await db.query(
      'interest_ledger',
      where: 'account_id = ? AND is_posted = 0',
      whereArgs: [accountId],
      orderBy: 'date ASC',
    );
  }

  /// Marks a list of ledger log IDs as posted (is_posted = 1)
  Future<void> markLogsAsPosted(
    List<int> logIds, [
    DatabaseExecutor? executor,
  ]) async {
    if (logIds.isEmpty) return;
    final db = executor ?? await DatabaseHelper.initDb();
    final placeholders = List.filled(logIds.length, '?').join(',');

    await db.rawUpdate(
      'UPDATE interest_ledger SET is_posted = 1 WHERE id IN ($placeholders)',
      logIds,
    );
  }

  /// Returns total pending net interest for an account from unposted ledger entries
  Future<double> getPendingInterestForAccount(
    int accountId, [
    DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await DatabaseHelper.initDb();
    final result = await db.rawQuery(
      'SELECT SUM(net_interest) as total_pending FROM interest_ledger WHERE account_id = ? AND is_posted = 0',
      [accountId],
    );

    if (result.isEmpty) return 0.0;
    return (result.first['total_pending'] as num?)?.toDouble() ?? 0.0;
  }
}
