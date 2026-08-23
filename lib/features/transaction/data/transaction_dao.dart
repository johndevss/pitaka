// lib/data/transaction_dao.dart

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
      // Evaluate actual account balance inside the atomic transaction
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

  // READ — all transactions, most recent first
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await DatabaseHelper.initDb();
    final result = await db.query('transactions', orderBy: 'created_at DESC');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — transactions for a single account (e.g. viewing one account's history)
  Future<List<TransactionModel>> getTransactionsByAccount(int accountId) async {
    final db = await DatabaseHelper.initDb();
    final result = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // READ — transactions from today (or a specific date) with precise millisecond boundaries
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

    final result = await db.query(
      'transactions',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'created_at DESC',
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
