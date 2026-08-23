// lib/models/category.dart

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
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_key': iconKey,
      'color_hex': colorHex,
      'type': type.value,
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
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? iconKey,
    String? colorHex,
    CategoryType? type,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
