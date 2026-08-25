// lib/features/account/models/account_interest_config.dart

class AccountInterestConfig {
  final int accountId;
  final double interestRate;
  final String calcMode; // 'daily_payout', 'daily_accrue_monthly_payout'
  final String payoutFrequency; // 'daily', 'monthly'
  final int payoutDay; // 1-31
  final double withholdingTaxRate; // Default 0.20
  final double? tierCapAmount;
  final double? secondaryInterestRate;
  final bool autoPost;
  final String? lastInterestAppliedDate;

  const AccountInterestConfig({
    required this.accountId,
    required this.interestRate,
    this.calcMode = 'daily_payout',
    this.payoutFrequency = 'daily',
    this.payoutDay = 1,
    this.withholdingTaxRate = 0.20,
    this.tierCapAmount,
    this.secondaryInterestRate,
    this.autoPost = true,
    this.lastInterestAppliedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'interest_rate': interestRate,
      'calc_mode': calcMode,
      'payout_frequency': payoutFrequency,
      'payout_day': payoutDay,
      'withholding_tax_rate': withholdingTaxRate,
      'tier_cap_amount': tierCapAmount,
      'secondary_interest_rate': secondaryInterestRate,
      'auto_post': autoPost ? 1 : 0,
      'last_interest_applied_date': lastInterestAppliedDate,
    };
  }

  factory AccountInterestConfig.fromMap(Map<String, dynamic> map) {
    return AccountInterestConfig(
      accountId: map['account_id'] as int,
      interestRate: (map['interest_rate'] as num).toDouble(),
      calcMode: map['calc_mode'] as String? ?? 'daily_payout',
      payoutFrequency: map['payout_frequency'] as String? ?? 'daily',
      payoutDay: map['payout_day'] as int? ?? 1,
      withholdingTaxRate:
          (map['withholding_tax_rate'] as num?)?.toDouble() ?? 0.20,
      tierCapAmount: (map['tier_cap_amount'] as num?)?.toDouble(),
      secondaryInterestRate: (map['secondary_interest_rate'] as num?)
          ?.toDouble(),
      autoPost: (map['auto_post'] as int?) != 0,
      lastInterestAppliedDate: map['last_interest_applied_date'] as String?,
    );
  }
}
