// lib/features/account/models/account.dart

class Account {
  final int? id;
  final String? name;
  final String? institutionId;
  final String accountType; // 'bank', 'e-wallet', 'cash', 'credit'
  final double initialBalance;
  final double? currentBalance; // Calculated/joined field
  final double pendingInterest; // Accrued interest in ledger
  final String currency;
  final String? colorHex;
  final String? iconKey;
  final bool isArchived;
  final DateTime createdAt;

  // Joined configuration fields
  final double? interestRate;
  final String? calcMode;
  final String? interestType;
  final String? provider;
  final DateTime? lastInterestAppliedDate;

  Account({
    this.id,
    this.name,
    this.institutionId,
    String accountType = 'e-wallet',
    double initialBalance = 0.0,
    double? currentBalance,
    this.pendingInterest = 0.0,
    required this.currency,
    this.colorHex,
    this.iconKey,
    this.isArchived = false,
    required this.createdAt,
    this.interestRate,
    this.calcMode,
    this.interestType,
    this.provider,
    this.lastInterestAppliedDate,
    String? type,
    double? balance,
  }) : accountType = accountType.isNotEmpty
           ? accountType
           : (type ?? 'e-wallet'),
       initialBalance = balance ?? initialBalance,
       currentBalance = currentBalance ?? balance ?? initialBalance;

  // Backward-compatibility getters
  String get type => accountType;
  String get providerName => provider ?? institutionId ?? 'custom';
  double get balance => currentBalance ?? initialBalance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'institution_id': institutionId,
      'account_type': accountType,
      'type': accountType,
      'provider': provider,
      'initial_balance': initialBalance,
      'balance': currentBalance ?? initialBalance,
      'currency': currency,
      'color_hex': colorHex,
      'icon_key': iconKey,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final rawAccountType =
        map['account_type'] as String? ?? map['type'] as String? ?? 'e-wallet';
    final rawInitial =
        (map['initial_balance'] as num?)?.toDouble() ??
        (map['balance'] as num?)?.toDouble() ??
        0.0;
    final rawCurrent =
        (map['current_balance'] as num?)?.toDouble() ??
        (map['balance'] as num?)?.toDouble() ??
        rawInitial;

    return Account(
      id: map['id'] as int?,
      name: map['name'] as String?,
      institutionId: map['institution_id'] as String?,
      accountType: rawAccountType,
      initialBalance: rawInitial,
      currentBalance: rawCurrent,
      pendingInterest: (map['pending_interest'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'PHP',
      colorHex: map['color_hex'] as String?,
      iconKey: map['icon_key'] as String?,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      interestRate: (map['interest_rate'] as num?)?.toDouble(),
      calcMode: map['calc_mode'] as String?,
      interestType: () {
        final rawCalc = map['calc_mode'] as String?;
        final rawFreq = map['payout_frequency'] as String?;
        final rawType = map['interest_type'] as String?;

        if (rawFreq != null && rawFreq.isNotEmpty) {
          return rawFreq;
        }
        if (rawCalc != null) {
          if (rawCalc == 'daily_payout' || rawCalc == 'daily') {
            return 'daily';
          }
          if (rawCalc == 'daily_accrue_monthly_payout' ||
              rawCalc == 'monthly') {
            return 'monthly';
          }
        }
        if (rawType != null && rawType != 'none') {
          return rawType;
        }
        return null;
      }(),
      provider: map['provider'] as String? ?? map['institution_id'] as String?,
      lastInterestAppliedDate: map['last_interest_applied_date'] != null
          ? DateTime.parse(map['last_interest_applied_date'] as String)
          : null,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    String? institutionId,
    String? accountType,
    double? initialBalance,
    double? currentBalance,
    double? pendingInterest,
    String? currency,
    String? colorHex,
    String? iconKey,
    bool? isArchived,
    DateTime? createdAt,
    double? interestRate,
    String? calcMode,
    String? interestType,
    String? provider,
    DateTime? lastInterestAppliedDate,
    String? type,
    double? balance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      institutionId: institutionId ?? this.institutionId,
      accountType: accountType ?? type ?? this.accountType,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? balance ?? this.currentBalance,
      pendingInterest: pendingInterest ?? this.pendingInterest,
      currency: currency ?? this.currency,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      interestRate: interestRate ?? this.interestRate,
      calcMode: calcMode ?? this.calcMode,
      interestType: interestType ?? this.interestType,
      provider: provider ?? this.provider,
      lastInterestAppliedDate:
          lastInterestAppliedDate ?? this.lastInterestAppliedDate,
    );
  }
}
