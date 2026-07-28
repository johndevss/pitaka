// lib/data/category_dao.dart

import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import 'database_helper.dart';

class CategoryDao {
  Future<Database> get _db async => DatabaseHelper.initDb();

  Future<int> insertCategory(Category category) async {
    final db = await _db;
    return db.insert('categories', category.toMap()..remove('id'));
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'created_at ASC');
    return rows.map((row) => Category.fromMap(row)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await _db;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _db;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
