// lib/models/account.dart
class Account {
  final int? id;
  final String name;
  final String type;
  final double balance;
  final double? interestRate;
  final DateTime createdAt;

  Account( {
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.interestRate,
    required this.createdAt,
  });

  // Converts Account object to a Map, to allow sqflite to insert and update rows in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'interest_rate': interestRate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Converts map back to account object to read data out of SQLite
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: map['balance'] as double,
      interestRate: map['interest_rate'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Updates balance after a transaction
  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
    double? interestRate,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      interestRate: interestRate ?? this.interestRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}