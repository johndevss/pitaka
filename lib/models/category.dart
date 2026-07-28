// lib/models/category.dart

class Category {
  final int? id;
  final String name;
  final String iconKey;
  final String colorHex;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_key': iconKey,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconKey: map['icon_key'] as String,
      colorHex: map['color_hex'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? iconKey,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
