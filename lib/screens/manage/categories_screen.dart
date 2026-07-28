// lib/screens/manage/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../providers/category_providers.dart';
import '../../utils/category_icons.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CategoryType get _currentType =>
      _tabController.index == 0 ? CategoryType.expense : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _openEditor(context, ref: ref, existing: null, type: _currentType),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(type: CategoryType.expense),
          _CategoryList(type: CategoryType.income),
        ],
      ),
    );
  }
}

void _openEditor(
  BuildContext context, {
  required WidgetRef ref,
  required Category? existing,
  required CategoryType type,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryEditorSheet(existing: existing, type: type),
  );
}

class _CategoryList extends ConsumerWidget {
  final CategoryType type;

  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(type));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Couldn\'t load categories: $err')),
      data: (categories) {
        if (categories.isEmpty) {
          final label = type == CategoryType.expense ? 'expense' : 'income';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No $label categories yet.\nTap + to add your first one.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = colorFromHex(category.colorHex);

            return Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openEditor(
                  context,
                  ref: ref,
                  existing: category,
                  type: type,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          iconForKey(category.iconKey),
                          size: 20,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDelete(context, ref, category),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Deleting "${category.name}" won\'t change any past transactions '
          '— they keep the category name as-is. You just won\'t be able to '
          'pick it for new transactions anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final dao = ref.read(categoryDaoProvider);
              await dao.deleteCategory(category.id!);
              ref.invalidate(categoriesProvider);
              ref.invalidate(categoriesByTypeProvider(category.type));
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryEditorSheet extends ConsumerStatefulWidget {
  final Category? existing;
  final CategoryType type;

  const _CategoryEditorSheet({required this.existing, required this.type});

  @override
  ConsumerState<_CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final TextEditingController _nameController;
  late String _selectedIconKey;
  late Color _selectedColor;

  bool get _isEditing => widget.existing != null;
  CategoryType get _type => widget.existing?.type ?? widget.type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIconKey = widget.existing?.iconKey ?? categoryIconMap.keys.first;
    _selectedColor = widget.existing != null
        ? colorFromHex(widget.existing!.colorHex)
        : categoryColorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Give the category a name')));
      return;
    }

    final dao = ref.read(categoryDaoProvider);

    if (_isEditing) {
      await dao.updateCategory(
        widget.existing!.copyWith(
          name: name,
          iconKey: _selectedIconKey,
          colorHex: colorToHex(_selectedColor),
        ),
      );
    } else {
      await dao.insertCategory(
        Category(
          name: name,
          iconKey: _selectedIconKey,
          colorHex: colorToHex(_selectedColor),
          type: _type,
          createdAt: DateTime.now(),
        ),
      );
    }
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoriesByTypeProvider(_type));

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing
                ? 'Edit Category'
                : _type == CategoryType.expense
                ? 'New Expense Category'
                : 'New Income Category',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: !_isEditing,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Groceries',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categoryIconOptions.map((entry) {
              final isSelected = _selectedIconKey == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedIconKey = entry.key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _selectedColor.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    entry.value,
                    color: isSelected ? _selectedColor : Colors.grey.shade600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categoryColorPalette.map((color) {
              final isSelected = _selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black87, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save Changes' : 'Add Category'),
            ),
          ),
        ],
      ),
    );
  }
}
