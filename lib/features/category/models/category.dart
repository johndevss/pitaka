// lib/features/category/models/category.dart

enum CategoryType { expense, income }

extension CategoryTypeStorage on CategoryType {
  /// The string stored in categories.type
  String get value => this == CategoryType.expense ? 'expense' : 'income';

  static CategoryType fromValue(String value) {
    return value == 'income' ? CategoryType.income : CategoryType.expense;
  }
}

class Category {
  final int? id;
  final String name;
  final String iconKey;
  final String colorHex;
  final CategoryType type;
  final int? parentId;
  final bool isSystem;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.type,
    this.parentId,
    this.isSystem = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_key': iconKey,
      'color_hex': colorHex,
      'type': type.value,
      'parent_id': parentId,
      'is_system': isSystem ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconKey: map['icon_key'] as String,
      colorHex: map['color_hex'] as String,
      type: CategoryTypeStorage.fromValue(map['type'] as String),
      parentId: map['parent_id'] as int?,
      isSystem: (map['is_system'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? iconKey,
    String? colorHex,
    CategoryType? type,
    int? parentId,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
