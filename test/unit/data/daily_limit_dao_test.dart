import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pitaka/data/daily_limit_dao.dart';
import 'package:pitaka/data/database_helper.dart';
import 'package:pitaka/models/daily_limit.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await DatabaseHelper.initDb();
    await db.delete('daily_limits');
  });

  final dao = DailyLimitDao();

  test('insertDailyLimit then getAllDailyLimits returns it', () async {
    await dao.insertDailyLimit(
      DailyLimit(amount: 500.0, effectiveDate: DateTime(2026, 1, 1)),
    );

    final all = await dao.getAllDailyLimits();

    expect(all.length, equals(1));
    expect(all.first.amount, equals(500.0));
  });

  test(
    'getCurrentDailyLimit returns the most recent past-or-today limit, ignoring future ones',
    () async {
      final now = DateTime.now();

      await dao.insertDailyLimit(
        DailyLimit(
          amount: 300.0,
          effectiveDate: now.subtract(const Duration(days: 10)),
        ),
      );
      await dao.insertDailyLimit(
        DailyLimit(
          amount: 500.0,
          effectiveDate: now.subtract(
            const Duration(days: 1),
          ), // most recent valid
        ),
      );
      await dao.insertDailyLimit(
        DailyLimit(
          amount: 999.0,
          effectiveDate: now.add(
            const Duration(days: 5),
          ), // future — must be ignored
        ),
      );

      final current = await dao.getCurrentDailyLimit();

      expect(current, isNotNull);
      expect(current!.amount, equals(500.0));
    },
  );

  test(
    'getCurrentDailyLimit returns null when no limit has been set',
    () async {
      final current = await dao.getCurrentDailyLimit();
      expect(current, isNull);
    },
  );

  test('updateDailyLimit persists changes', () async {
    await dao.insertDailyLimit(
      DailyLimit(amount: 500.0, effectiveDate: DateTime(2026, 1, 1)),
    );

    final all = await dao.getAllDailyLimits();
    final updated = all.first.copyWith(amount: 750.0);
    await dao.updateDailyLimit(updated);

    final result = await dao.getAllDailyLimits();
    expect(result.first.amount, equals(750.0));
  });

  test('deleteDailyLimit removes it', () async {
    final id = await dao.insertDailyLimit(
      DailyLimit(amount: 500.0, effectiveDate: DateTime(2026, 1, 1)),
    );

    await dao.deleteDailyLimit(id);

    final all = await dao.getAllDailyLimits();
    expect(all, isEmpty);
  });
}
