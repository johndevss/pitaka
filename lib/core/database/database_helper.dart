// lib/data/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _dbName = 'pitaka.db';
  static const _dbVersion = 2;

  // Add a static variable to hold the open database connection
  static Database? _database;

  static void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  static Future<Database> initDb() async {
    // Return the cached instance immediately if it's already initialized
    if (_database != null) return _database!;

    final path = join(await getDatabasesPath(), _dbName);

    // Open it once and assign it to the static variable
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );

    return _database!;
  }

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        provider TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'PHP',
        interest_rate REAL,
        interest_type TEXT NOT NULL DEFAULT 'none',
        last_interest_applied_date TEXT,
        icon_key TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        category TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_limits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        effective_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        created_at TEXT NOT NULL
      )
    ''');

    await _seedDefaultCategories(db);
  }

  static Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      {
        'name': 'Food',
        'icon_key': 'restaurant',
        'color_hex': 'FFD9A441',
        'type': 'expense',
      },
      {
        'name': 'Transport',
        'icon_key': 'car',
        'color_hex': 'FF1F8A5B',
        'type': 'expense',
      },
      {
        'name': 'Bills',
        'icon_key': 'receipt',
        'color_hex': 'FFD64545',
        'type': 'expense',
      },
      {
        'name': 'Shopping',
        'icon_key': 'shopping_bag',
        'color_hex': 'FF3AA76D',
        'type': 'expense',
      },
      {
        'name': 'Salary',
        'icon_key': 'salary',
        'color_hex': 'FF1F8A5B',
        'type': 'income',
      },
      {
        'name': 'Allowance',
        'icon_key': 'wallet',
        'color_hex': 'FF3A6FD6',
        'type': 'income',
      },
      {
        'name': 'Gift',
        'icon_key': 'gift',
        'color_hex': 'FFD65C9E',
        'type': 'income',
      },
      {
        'name': 'Other Income',
        'icon_key': 'other',
        'color_hex': 'FF6B7280',
        'type': 'income',
      },
    ];

    for (final cat in defaults) {
      await db.insert('categories', {...cat, 'created_at': now});
    }
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon_key TEXT NOT NULL,
          color_hex TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'expense',
          created_at TEXT NOT NULL
        )
      ''');
      await _seedDefaultCategories(db);
    }
  }
}
