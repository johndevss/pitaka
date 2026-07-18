// lib/data/account_dao.dart

import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import 'database_helper.dart';

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
  Future<Account?> getAccountById(int id) async {
    final db = await DatabaseHelper.initDb();
    final result = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
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
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}