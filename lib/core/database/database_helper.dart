// lib/core/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pitaka/features/account/models/institution.dart';

class DatabaseHelper {
  static const _dbName = 'pitaka.db';
  static const _dbVersion = 1;

  static Database? _database;

  static void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  static Future<Database> initDb() async {
    if (_database != null) return _database!;

    final path = join(await getDatabasesPath(), _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
        await db.rawQuery('PRAGMA synchronous = NORMAL');
        await db.rawQuery('PRAGMA cache_size = -64000');
        await db.rawQuery('PRAGMA temp_store = MEMORY');
      },
      onCreate: onCreate,
    );

    return _database!;
  }

  static Future<void> onCreate(Database db, int version) async {
    // 1. INSTITUTIONS
    await db.execute('''
      CREATE TABLE institutions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        default_currency TEXT NOT NULL DEFAULT 'PHP',
        has_interest INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. ACCOUNTS
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        institution_id TEXT,
        account_type TEXT NOT NULL DEFAULT 'bank',
        type TEXT,
        provider TEXT,
        initial_balance REAL NOT NULL DEFAULT 0.0,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'PHP',
        interest_rate REAL,
        interest_type TEXT NOT NULL DEFAULT 'none',
        last_interest_applied_date TEXT,
        color_hex TEXT,
        icon_key TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (institution_id) REFERENCES institutions (id) ON DELETE SET NULL
      )
    ''');

    // 3. ACCOUNT INTEREST CONFIGS
    await db.execute('''
      CREATE TABLE account_interest_configs (
        account_id INTEGER PRIMARY KEY,
        interest_rate REAL NOT NULL,
        calc_mode TEXT NOT NULL DEFAULT 'daily_accrue',
        payout_frequency TEXT NOT NULL DEFAULT 'monthly',
        payout_day INTEGER NOT NULL DEFAULT 1,
        withholding_tax_rate REAL NOT NULL DEFAULT 0.20,
        tier_cap_amount REAL,
        secondary_interest_rate REAL,
        auto_post INTEGER NOT NULL DEFAULT 1,
        last_interest_applied_date TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // 4. CATEGORIES
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        parent_id INTEGER,
        is_system INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 5. TRANSACTIONS
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        amount REAL NOT NULL,
        category TEXT,
        category_id INTEGER,
        destination_account_id INTEGER,
        gross_amount REAL,
        tax_amount REAL,
        note TEXT,
        transaction_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (destination_account_id) REFERENCES accounts (id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 6. INTEREST LEDGER
    await db.execute('''
      CREATE TABLE interest_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        closing_balance REAL NOT NULL,
        gross_interest REAL NOT NULL,
        tax_deducted REAL NOT NULL,
        net_interest REAL NOT NULL,
        is_posted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // 7. BUDGETS & DAILY LIMITS
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        amount REAL NOT NULL,
        period TEXT NOT NULL DEFAULT 'daily',
        effective_date TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_limits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        effective_date TEXT NOT NULL
      )
    ''');

    // 8. DAILY ACCOUNT SNAPSHOTS
    await db.execute('''
      CREATE TABLE daily_account_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        snapshot_date TEXT NOT NULL,
        ending_balance REAL NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        UNIQUE(account_id, snapshot_date)
      )
    ''');

    // INDEXES
    await db.execute(
      'CREATE INDEX idx_tx_date ON transactions (transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_type_date ON transactions (type, transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_cat_date ON transactions (category_id, transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_account_date ON transactions (account_id, transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_snapshots_date ON daily_account_snapshots (snapshot_date)',
    );

    // TRIGGERS
    await db.execute('''
      CREATE TRIGGER trg_update_daily_snapshot_insert
      AFTER INSERT ON transactions
      BEGIN
        INSERT INTO daily_account_snapshots (account_id, snapshot_date, ending_balance)
        VALUES (
          NEW.account_id, 
          DATE(NEW.transaction_date),
          (SELECT initial_balance FROM accounts WHERE id = NEW.account_id) + 
          (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE account_id = NEW.account_id AND DATE(transaction_date) <= DATE(NEW.transaction_date))
        )
        ON CONFLICT(account_id, snapshot_date) DO UPDATE SET
          ending_balance = excluded.ending_balance;
      END;
    ''');

    // ANALYTICS VIEWS
    await db.execute('''
      CREATE VIEW v_daily_analytics AS
      SELECT 
        DATE(transaction_date) AS tx_date,
        SUM(CASE WHEN type = 'income' OR type = 'interest' THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 'expense' THEN ABS(amount) ELSE 0 END) AS total_expense,
        SUM(CASE WHEN type = 'interest' THEN amount ELSE 0 END) AS total_interest_earned,
        SUM(CASE WHEN type = 'expense' THEN ABS(amount) ELSE 0 END) - 
        SUM(CASE WHEN type = 'income' OR type = 'interest' THEN amount ELSE 0 END) AS net_cashflow
      FROM transactions
      GROUP BY DATE(transaction_date);
    ''');

    await db.execute('''
      CREATE VIEW v_weekly_analytics AS
      SELECT 
        STRFTIME('%Y-%W', transaction_date) AS year_week,
        MIN(DATE(transaction_date)) AS week_start_date,
        SUM(CASE WHEN type = 'income' OR type = 'interest' THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 'expense' THEN ABS(amount) ELSE 0 END) AS total_expense,
        SUM(CASE WHEN type = 'interest' THEN amount ELSE 0 END) AS total_interest_earned
      FROM transactions
      GROUP BY STRFTIME('%Y-%W', transaction_date);
    ''');

    await db.execute('''
      CREATE VIEW v_monthly_category_analytics AS
      SELECT 
        STRFTIME('%Y-%m', t.transaction_date) AS year_month,
        c.id AS category_id,
        c.name AS category_name,
        c.color_hex,
        c.icon_key,
        t.type,
        SUM(ABS(t.amount)) AS total_amount,
        COUNT(t.id) AS transaction_count
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      GROUP BY STRFTIME('%Y-%m', t.transaction_date), c.id, t.type;
    ''');

    // SEEDERS
    await _seedDefaultInstitutions(db);
    await _seedDefaultCategories(db);
  }

  static Future<void> _seedDefaultInstitutions(Database db) async {
    final batch = db.batch();
    for (final inst in InstitutionRegistry.all) {
      batch.insert(
        'institutions',
        inst.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      {
        'name': 'Food',
        'icon_key': 'restaurant',
        'color_hex': 'FFD9A441',
        'type': 'expense',
        'is_system': 0,
      },
      {
        'name': 'Transport',
        'icon_key': 'car',
        'color_hex': 'FF1F8A5B',
        'type': 'expense',
        'is_system': 0,
      },
      {
        'name': 'Bills',
        'icon_key': 'receipt',
        'color_hex': 'FFD64545',
        'type': 'expense',
        'is_system': 0,
      },
      {
        'name': 'Shopping',
        'icon_key': 'shopping_bag',
        'color_hex': 'FF3AA76D',
        'type': 'expense',
        'is_system': 0,
      },
      {
        'name': 'Salary',
        'icon_key': 'salary',
        'color_hex': 'FF1F8A5B',
        'type': 'income',
        'is_system': 0,
      },
      {
        'name': 'Allowance',
        'icon_key': 'wallet',
        'color_hex': 'FF3A6FD6',
        'type': 'income',
        'is_system': 0,
      },
      {
        'name': 'Gift',
        'icon_key': 'gift',
        'color_hex': 'FFD65C9E',
        'type': 'income',
        'is_system': 0,
      },
      {
        'name': 'Interest Income',
        'icon_key': 'trending_up',
        'color_hex': 'FF22C55E',
        'type': 'income',
        'is_system': 1,
      },
      {
        'name': 'Other Income',
        'icon_key': 'other',
        'color_hex': 'FF6B7280',
        'type': 'income',
        'is_system': 0,
      },
    ];

    final batch = db.batch();
    for (final cat in defaults) {
      batch.insert('categories', {...cat, 'created_at': now});
    }
    await batch.commit(noResult: true);
  }
}
