// test/unit/models/category_dao_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pitaka/features/category/data/category_dao.dart';
import 'package:pitaka/core/database/database_helper.dart';
import 'package:pitaka/features/category/models/category.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: DatabaseHelper.onCreate,
        onUpgrade: DatabaseHelper.onUpgrade,
      ),
    );
    DatabaseHelper.setDatabaseForTesting(db);
  });

  setUp(() async {
    final db = await DatabaseHelper.initDb();
    await db.delete('categories');
  });

  final dao = CategoryDao();

  Category buildCategory({
    String name = 'Test Food',
    CategoryType type = CategoryType.expense,
  }) {
    return Category(
      name: name,
      iconKey: 'restaurant',
      colorHex: 'FFD9A441',
      type: type,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('insertCategory then getAllCategories returns it', () async {
    await dao.insertCategory(buildCategory());
    final all = await dao.getAllCategories();

    expect(all.length, equals(1));
    expect(all.first.name, equals('Test Food'));
  });

  test(
    'getAllCategories returns categories ordered by created_at ASC',
    () async {
      await dao.insertCategory(
        buildCategory(name: 'Older').copyWith(createdAt: DateTime(2026, 1, 1)),
      );
      await dao.insertCategory(
        buildCategory(name: 'Newer').copyWith(createdAt: DateTime(2026, 6, 1)),
      );

      final all = await dao.getAllCategories();

      expect(all.length, equals(2));
      expect(all.first.name, equals('Older'));
    },
  );

  test('updateCategory persists field changes', () async {
    final id = await dao.insertCategory(buildCategory());
    final all = await dao.getAllCategories();
    final original = all.first;

    await dao.updateCategory(original.copyWith(name: 'Renamed Category'));

    final result = (await dao.getAllCategories()).firstWhere((c) => c.id == id);
    expect(result.name, equals('Renamed Category'));
  });

  test('deleteCategory removes it', () async {
    final id = await dao.insertCategory(buildCategory());
    await dao.deleteCategory(id);

    final all = await dao.getAllCategories();
    expect(all, isEmpty);
  });

  group('getCategoriesByType', () {
    test('only returns categories matching the requested type', () async {
      await dao.insertCategory(
        buildCategory(name: 'Food', type: CategoryType.expense),
      );
      await dao.insertCategory(
        buildCategory(name: 'Transport', type: CategoryType.expense),
      );
      await dao.insertCategory(
        buildCategory(name: 'Salary', type: CategoryType.income),
      );

      final expenseCategories = await dao.getCategoriesByType(
        CategoryType.expense,
      );
      final incomeCategories = await dao.getCategoriesByType(
        CategoryType.income,
      );

      expect(expenseCategories.length, equals(2));
      expect(
        expenseCategories.map((c) => c.name),
        containsAll(['Food', 'Transport']),
      );
      expect(incomeCategories.length, equals(1));
      expect(incomeCategories.first.name, equals('Salary'));
    });

    test(
      'returns an empty list when no categories of that type exist',
      () async {
        await dao.insertCategory(
          buildCategory(name: 'Food', type: CategoryType.expense),
        );

        final incomeCategories = await dao.getCategoriesByType(
          CategoryType.income,
        );

        expect(incomeCategories, isEmpty);
      },
    );
  });
}
