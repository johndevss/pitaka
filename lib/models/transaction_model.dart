// lib/models/transaction_model.dart

class TransactionModel {
  final int? id;
  final int accountId;
  final double amount;
  final String? category;
  final String? note;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.accountId,
    required this.amount,
    this.category,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'amount': amount,
      'category': category,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TransactionModel copyWith({
    int? id,
    int? accountId,
    double? amount,
    String? category,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
