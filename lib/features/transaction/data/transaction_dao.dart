// lib/features/transaction/data/transaction_dao.dart

import 'package:sqflite/sqflite.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';
import 'package:pitaka/features/account/data/account_dao.dart';
import 'package:pitaka/core/database/database_helper.dart';

class InsufficientBalanceException implements Exception {
  final double available;
  final double requested;
  InsufficientBalanceException(this.available, this.requested);

  @override
  String toString() =>
      'InsufficientBalanceException: available $available, requested $requested';
}

class TransactionDao {
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await DatabaseHelper.initDb();
    return await db.transaction((txn) async {
      return await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<double> _getLiveBalance(
    DatabaseExecutor executor,
    int accountId,
  ) async {
    final result = await executor.rawQuery(
      '''SELECT COALESCE(initial_balance, 0) + COALESCE((
          SELECT SUM(amount) FROM transactions WHERE account_id = accounts.id
        ), 0) AS current_balance
        FROM accounts WHERE id = ?''',
      [accountId],
    );
    if (result.isEmpty) return 0;
    return (result.first['current_balance'] as num?)?.toDouble() ?? 0;
  }

  Future<void> transferFunds(
    TransactionModel expense,
    TransactionModel income, {
    double? currentBalance,
    AccountDao? accountDao,
  }) async {
    final requestedAmount = expense.amount.abs();
    final db = await DatabaseHelper.initDb();

    await db.transaction((txn) async {
      final liveBalance =
          currentBalance ?? await _getLiveBalance(txn, expense.accountId);

      if (liveBalance < requestedAmount) {
        throw InsufficientBalanceException(liveBalance, requestedAmount);
      }

      final groupId =
          expense.transferGroupId ??
          'transfer-${DateTime.now().microsecondsSinceEpoch}';
      final expenseLeg = expense.copyWith(
        type: 'transfer',
        destinationAccountId: income.accountId,
        transferGroupId: groupId,
        category: expense.category ?? 'Transfer Out',
        amount: -requestedAmount,
      );
      final incomeLeg = income.copyWith(
        type: 'transfer',
        destinationAccountId: expense.accountId,
        transferGroupId: groupId,
        category: income.category ?? 'Transfer In',
        amount: requestedAmount,
      );

      await txn.insert(
        'transactions',
        expenseLeg.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'transactions',
        incomeLeg.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // READ — all transactions, most recent first, with joined category name
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await DatabaseHelper.initDb();
    final result = await db.rawQuery('''
      SELECT 
        t.*,
        COALESCE(c.name, t.category) AS category
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      ORDER BY t.transaction_date DESC, t.id DESC
    ''');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — transactions for a single account
  Future<List<TransactionModel>> getTransactionsByAccount(int accountId) async {
    final db = await DatabaseHelper.initDb();
    final result = await db.rawQuery(
      '''
      SELECT 
        t.*,
        COALESCE(c.name, t.category) AS category
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.account_id = ?
      ORDER BY t.transaction_date DESC, t.id DESC
    ''',
      [accountId],
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — transactions from today (or a specific date)
  Future<List<TransactionModel>> getTodayTransactions([
    DateTime? targetDate,
  ]) async {
    final db = await DatabaseHelper.initDb();
    final date = targetDate ?? DateTime.now();
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      0,
      0,
      0,
      0,
      0,
    ).toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
      999,
    ).toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT 
        t.*,
        COALESCE(c.name, t.category) AS category
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.transaction_date BETWEEN ? AND ?
      ORDER BY t.transaction_date DESC, t.id DESC
    ''',
      [startOfDay, endOfDay],
    );

    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // UPDATE
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await DatabaseHelper.initDb();
    if (transaction.id == null) return 0;

    return await db.transaction((txn) async {
      final oldRows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
        limit: 1,
      );
      if (oldRows.isEmpty) return 0;
      final old = TransactionModel.fromMap(oldRows.first);

      if (old.transferGroupId != null) {
        final legs = await txn.query(
          'transactions',
          where: 'transfer_group_id = ?',
          whereArgs: [old.transferGroupId],
        );
        if (legs.length == 2) {
          final source = legs.firstWhere(
            (row) => (row['amount'] as num).toDouble() < 0,
          );
          final receiver = legs.firstWhere(
            (row) => (row['amount'] as num).toDouble() > 0,
          );

          final sourceOld = TransactionModel.fromMap(source);
          final receiverOld = TransactionModel.fromMap(receiver);
          final requested = transaction.amount.abs();
          final destinationId =
              transaction.destinationAccountId ?? receiverOld.accountId;

          final sourceBalance = await _getLiveBalance(
            txn,
            transaction.accountId,
          );
          final finalSourceBalance = sourceBalance - sourceOld.amount.abs();
          if (transaction.amount < 0 && finalSourceBalance < requested) {
            throw InsufficientBalanceException(finalSourceBalance, requested);
          }

          await txn.delete(
            'transactions',
            where: 'transfer_group_id = ?',
            whereArgs: [old.transferGroupId],
          );

          final now = DateTime.now();
          final groupId = old.transferGroupId!;
          await txn.insert(
            'transactions',
            TransactionModel(
              accountId: transaction.accountId,
              destinationAccountId: destinationId,
              transferGroupId: groupId,
              type: 'transfer',
              amount: -requested,
              category: 'Transfer Out',
              note: transaction.note,
              transactionDate: transaction.transactionDate,
              createdAt: now,
            ).toMap(),
          );
          await txn.insert(
            'transactions',
            TransactionModel(
              accountId: destinationId,
              destinationAccountId: transaction.accountId,
              transferGroupId: groupId,
              type: 'transfer',
              amount: requested,
              category: 'Transfer In',
              note: transaction.note,
              transactionDate: transaction.transactionDate,
              createdAt: now,
            ).toMap(),
          );
          return 2;
        }
      }

      if (old.accountId != transaction.accountId) {
        final finalOldAccountBalance =
            await _getLiveBalance(txn, old.accountId) - old.amount;
        if (transaction.amount < 0 &&
            await _getLiveBalance(txn, transaction.accountId) <
                transaction.amount.abs()) {
          throw InsufficientBalanceException(
            await _getLiveBalance(txn, transaction.accountId),
            transaction.amount.abs(),
          );
        }
        finalOldAccountBalance;
      } else if (transaction.amount < 0) {
        final balanceWithoutOld =
            await _getLiveBalance(txn, old.accountId) - old.amount;
        if (balanceWithoutOld < transaction.amount.abs()) {
          throw InsufficientBalanceException(
            balanceWithoutOld,
            transaction.amount.abs(),
          );
        }
      }

      return await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });
  }

  // DELETE
  Future<int> deleteTransaction(int id) async {
    final db = await DatabaseHelper.initDb();

    return await db.transaction((txn) async {
      final rows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return 0;

      final transaction = TransactionModel.fromMap(rows.first);
      if (transaction.transferGroupId != null) {
        return await txn.delete(
          'transactions',
          where: 'transfer_group_id = ?',
          whereArgs: [transaction.transferGroupId],
        );
      }

      return await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }
}
