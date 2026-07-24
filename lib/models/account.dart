// lib/models/account.dart
class Account {
  final int? id;
  final String? name;
  final String type;
  final String provider;
  final double balance;
  final String currency;
  final double? interestRate;
  final String interestType;
  final DateTime? lastInterestAppliedDate;
  final String? iconKey;
  final DateTime createdAt;

  Account({
    this.id,
    this.name,
    required this.type,
    required this.provider,
    required this.balance,
    required this.currency,
    this.interestRate,
    required this.interestType,
    this.lastInterestAppliedDate,
    this.iconKey,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Converts Account object to a Map, to allow sqflite to insert and update rows in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'provider': provider,
      'balance': balance,
      'currency': currency,
      'interest_rate': interestRate,
      'interest_type': interestType,
      'last_interest_applied_date': lastInterestAppliedDate?.toIso8601String(),
      'icon_key': iconKey,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Converts map back to account object to read data out of SQLite
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String?,
      type: map['type'] as String,
      provider: map['provider'] as String,
      balance: map['balance'] as double,
      currency: map['currency'] as String,
      interestRate: map['interest_rate'] as double?,
      interestType: map['interest_type'] as String,
      lastInterestAppliedDate: map['last_interest_applied_date'] != null
          ? DateTime.parse(map['last_interest_applied_date'] as String)
          : null,
      iconKey: map['icon_key'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Updates balance after a transaction
  Account copyWith({
    int? id,
    String? name,
    String? type,
    String? provider,
    double? balance,
    String? currency,
    double? interestRate,
    String? interestType,
    DateTime? lastInterestAppliedDate,
    String? iconKey,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      lastInterestAppliedDate:
          lastInterestAppliedDate ?? this.lastInterestAppliedDate,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
