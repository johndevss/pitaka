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
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> transferFunds(
    TransactionModel expense,
    TransactionModel income, {
    double? currentBalance,
    AccountDao? accountDao,
  }) async {
    final requestedAmount = expense.amount.abs();
    final db = await DatabaseHelper.initDb();
    final dao = accountDao ?? AccountDao();

    await db.transaction((txn) async {
      final liveBalance =
          currentBalance ?? await dao.getCurrentBalance(expense.accountId, txn);

      if (liveBalance < requestedAmount) {
        throw InsufficientBalanceException(liveBalance, requestedAmount);
      }

      await txn.insert(
        'transactions',
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'transactions',
        income.toMap(),
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
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // DELETE
  Future<int> deleteTransaction(int id) async {
    final db = await DatabaseHelper.initDb();
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
