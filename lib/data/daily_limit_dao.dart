// lib/data/daily_limit_dao.dart

import 'package:sqflite/sqflite.dart';
import '../models/daily_limit.dart';
import 'database_helper.dart';

class DailyLimitDao {
  // CREATE
  Future<int> insertDailyLimit(DailyLimit limit) async {
    final db = await DatabaseHelper.initDb();
    return await db.insert(
      'daily_limits',
      limit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ — all daily limits ever set, most recent first
  Future<List<DailyLimit>> getAllDailyLimits() async {
    final db = await DatabaseHelper.initDb();
    final result = await db.query(
      'daily_limits',
      orderBy: 'effective_date DESC',
    );
    return result.map((map) => DailyLimit.fromMap(map)).toList();
  }

  // READ — the most recently set limit that is effective today or earlier
  // (i.e. the "current" limit that applies right now)
  Future<DailyLimit?> getCurrentDailyLimit() async {
    final db = await DatabaseHelper.initDb();
    final now = DateTime.now().toIso8601String();

    final result = await db.query(
      'daily_limits',
      where: 'effective_date <= ?',
      whereArgs: [now],
      orderBy: 'effective_date DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DailyLimit.fromMap(result.first);
  }

  // UPDATE
  Future<int> updateDailyLimit(DailyLimit limit) async {
    final db = await DatabaseHelper.initDb();
    return await db.update(
      'daily_limits',
      limit.toMap(),
      where: 'id = ?',
      whereArgs: [limit.id],
    );
  }

  // DELETE
  Future<int> deleteDailyLimit(int id) async {
    final db = await DatabaseHelper.initDb();
    return await db.delete('daily_limits', where: 'id = ?', whereArgs: [id]);
  }
}
