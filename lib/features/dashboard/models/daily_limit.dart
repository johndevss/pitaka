// lib/models/daily_limit.dart

class DailyLimit {
  final int? id;
  final double amount;
  final DateTime effectiveDate;

  DailyLimit({this.id, required this.amount, required this.effectiveDate});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'effective_date': effectiveDate.toIso8601String(),
    };
  }

  factory DailyLimit.fromMap(Map<String, dynamic> map) {
    return DailyLimit(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      effectiveDate: DateTime.parse(map['effective_date'] as String),
    );
  }

  DailyLimit copyWith({int? id, double? amount, DateTime? effectiveDate}) {
    return DailyLimit(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }
}
