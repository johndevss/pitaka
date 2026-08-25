// lib/features/transaction/models/transaction_model.dart

class TransactionModel {
  final int? id;
  final int accountId;
  final String type; // 'expense', 'income', 'transfer', 'interest'
  final double amount;
  final int? categoryId;
  final String? category; // Joined category name for UI display
  final int? destinationAccountId;
  final double? grossAmount;
  final double? taxAmount;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.accountId,
    this.type = 'expense',
    required this.amount,
    this.categoryId,
    this.category,
    this.destinationAccountId,
    this.grossAmount,
    this.taxAmount,
    this.note,
    DateTime? transactionDate,
    required this.createdAt,
  }) : transactionDate = transactionDate ?? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'category': category,
      'destination_account_id': destinationAccountId,
      'gross_amount': grossAmount,
      'tax_amount': taxAmount,
      'note': note,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final rawType =
        map['type'] as String? ??
        (map['amount'] != null && (map['amount'] as num) > 0
            ? 'income'
            : 'expense');
    final txDateStr =
        map['transaction_date'] as String? ?? map['created_at'] as String?;
    final txDate = txDateStr != null
        ? DateTime.parse(txDateStr)
        : DateTime.now();

    return TransactionModel(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      type: rawType,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int?,
      category: map['category'] as String?,
      destinationAccountId: map['destination_account_id'] as int?,
      grossAmount: (map['gross_amount'] as num?)?.toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble(),
      note: map['note'] as String?,
      transactionDate: txDate,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : txDate,
    );
  }

  TransactionModel copyWith({
    int? id,
    int? accountId,
    String? type,
    double? amount,
    int? categoryId,
    String? category,
    int? destinationAccountId,
    double? grossAmount,
    double? taxAmount,
    String? note,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      grossAmount: grossAmount ?? this.grossAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
