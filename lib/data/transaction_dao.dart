// lib/data/transaction_dao.dart

import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import 'database_helper.dart';

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
    required double currentBalance,
  }) async {
    final requestedAmount = expense.amount.abs();

    if (currentBalance < requestedAmount) {
      throw InsufficientBalanceException(currentBalance, requestedAmount);
    }

    final db = await DatabaseHelper.initDb();
    await db.transaction((txn) async {
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

  // READ — transactions from today only (needed for the Daily Limit feature)
  Future<List<TransactionModel>> getTodayTransactions() async {
    final db = await DatabaseHelper.initDb();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
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
