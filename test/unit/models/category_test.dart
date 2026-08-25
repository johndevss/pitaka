// test/unit/models/category_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/features/category/models/category.dart';

void main() {
  test('Category.copyWith preserves unaltered fields', () {
    final category = Category(
      id: 1,
      name: 'Food',
      iconKey: 'restaurant',
      colorHex: 'FFD9A441',
      type: CategoryType.expense,
      createdAt: DateTime(2026, 5, 1),
    );

    final updated = category.copyWith(name: 'Groceries');

    expect(updated.id, equals(1));
    expect(updated.name, equals('Groceries'));
    expect(updated.iconKey, equals('restaurant'));
    expect(updated.colorHex, equals('FFD9A441'));
    expect(updated.type, equals(CategoryType.expense));
  });

  test('Category.toMap stores type as its string value', () {
    final category = Category(
      name: 'Salary',
      iconKey: 'salary',
      colorHex: 'FF1F8A5B',
      type: CategoryType.income,
      createdAt: DateTime(2026, 7, 19),
    );

    final map = category.toMap();

    expect(map['type'], equals('income'));
  });

  test('Category.fromMap round-trips toMap for both types', () {
    final expense = Category(
      name: 'Bills',
      iconKey: 'receipt',
      colorHex: 'FFD64545',
      type: CategoryType.expense,
      createdAt: DateTime(2026, 1, 1),
    );
    final income = expense.copyWith(name: 'Gift', type: CategoryType.income);

    final rebuiltExpense = Category.fromMap(expense.toMap());
    final rebuiltIncome = Category.fromMap(income.toMap());

    expect(rebuiltExpense.type, equals(CategoryType.expense));
    expect(rebuiltIncome.type, equals(CategoryType.income));
  });

  group('CategoryTypeStorage', () {
    test('value maps expense/income to their stored strings', () {
      expect(CategoryType.expense.value, equals('expense'));
      expect(CategoryType.income.value, equals('income'));
    });

    test('fromValue maps back to the correct enum, defaulting to expense', () {
      expect(
        CategoryTypeStorage.fromValue('income'),
        equals(CategoryType.income),
      );
      expect(
        CategoryTypeStorage.fromValue('expense'),
        equals(CategoryType.expense),
      );
      // Guards the DB migration's DEFAULT 'expense' behavior
      expect(
        CategoryTypeStorage.fromValue('garbage'),
        equals(CategoryType.expense),
      );
    });
  });
}
