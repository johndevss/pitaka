// test/unit/database/database_helper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pitaka/core/database/database_helper.dart';

void main() {
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
        },
        onCreate: DatabaseHelper.onCreate,
      ),
    );
    DatabaseHelper.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  group('DatabaseHelper v1 Schema Tests', () {
    test('creates all required v1 tables', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(tableNames, contains('institutions'));
      expect(tableNames, contains('accounts'));
      expect(tableNames, contains('account_interest_configs'));
      expect(tableNames, contains('categories'));
      expect(tableNames, contains('transactions'));
      expect(tableNames, contains('interest_ledger'));
      expect(tableNames, contains('budgets'));
      expect(tableNames, contains('daily_account_snapshots'));
    });

    test('seeds default institutions on database creation', () async {
      final institutions = await db.query('institutions');
      expect(institutions, isNotEmpty);
      expect(institutions.any((i) => i['id'] == 'seabank'), isTrue);
      expect(institutions.any((i) => i['id'] == 'gotyme'), isTrue);
      expect(institutions.any((i) => i['id'] == 'gcash'), isTrue);
    });

    test('seeds default categories including system Interest Income', () async {
      final categories = await db.query('categories');
      expect(categories, isNotEmpty);
      expect(categories.any((c) => c['name'] == 'Food'), isTrue);
      expect(
        categories.any(
          (c) => c['name'] == 'Interest Income' && c['is_system'] == 1,
        ),
        isTrue,
      );
    });

    test('creates all SQL analytics views', () async {
      final views = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='view'",
      );
      final viewNames = views.map((v) => v['name'] as String).toSet();

      expect(viewNames, contains('v_daily_analytics'));
      expect(viewNames, contains('v_weekly_analytics'));
      expect(viewNames, contains('v_monthly_category_analytics'));
    });

    test(
      'trigger automatically maintains daily_account_snapshots on transaction insert',
      () async {
        // 1. Create account
        final accountId = await db.insert('accounts', {
          'name': 'Test Savings',
          'institution_id': 'seabank',
          'account_type': 'bank',
          'initial_balance': 1000.0,
          'currency': 'PHP',
          'created_at': '2026-08-23T10:00:00Z',
        });

        // 2. Insert transaction
        await db.insert('transactions', {
          'account_id': accountId,
          'type': 'expense',
          'amount': -200.0,
          'transaction_date': '2026-08-23T12:00:00Z',
        });

        // 3. Verify snapshot trigger calculated 1000 - 200 = 800
        final snapshots = await db.query(
          'daily_account_snapshots',
          where: 'account_id = ? AND snapshot_date = ?',
          whereArgs: [accountId, '2026-08-23'],
        );

        expect(snapshots, hasLength(1));
        expect(snapshots.first['ending_balance'], equals(800.0));
      },
    );

    test('analytics views query cleanly', () async {
      final dailyRes = await db.query('v_daily_analytics');
      expect(dailyRes, isNotNull);

      final weeklyRes = await db.query('v_weekly_analytics');
      expect(weeklyRes, isNotNull);

      final categoryRes = await db.query('v_monthly_category_analytics');
      expect(categoryRes, isNotNull);
    });
  });
}
