// lib/providers/category_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_dao.dart';
import '../models/category.dart';

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return CategoryDao();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dao = ref.watch(categoryDaoProvider);
  return dao.getAllCategories();
});

final categoriesByTypeProvider =
    FutureProvider.family<List<Category>, CategoryType>((ref, type) async {
      final dao = ref.watch(categoryDaoProvider);
      return dao.getCategoriesByType(type);
    });
