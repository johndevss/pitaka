// lib/features/account/services/interest_engine.dart

import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/account/models/account_interest_config.dart';

class InterestCalculationResult {
  final double closingBalance;
  final double grossInterest;
  final double taxDeducted;
  final double netInterest;

  const InterestCalculationResult({
    required this.closingBalance,
    required this.grossInterest,
    required this.taxDeducted,
    required this.netInterest,
  });

  Map<String, dynamic> toMap(int accountId, String dateIso) {
    return {
      'account_id': accountId,
      'date': dateIso,
      'closing_balance': closingBalance,
      'gross_interest': grossInterest,
      'tax_deducted': taxDeducted,
      'net_interest': netInterest,
      'is_posted': 0,
    };
  }
}

class InterestEngine {
  /// Calculates interest earned for a single day based on closing balance and interest config.
  static InterestCalculationResult calculateDailyInterest({
    required double closingBalance,
    required double annualRate,
    double withholdingTaxRate = 0.20,
    double? tierCapAmount,
    double? secondaryInterestRate,
  }) {
    if (closingBalance <= 0 || annualRate <= 0) {
      return InterestCalculationResult(
        closingBalance: closingBalance,
        grossInterest: 0.0,
        taxDeducted: 0.0,
        netInterest: 0.0,
      );
    }

    double grossInterest = 0.0;

    if (tierCapAmount != null &&
        tierCapAmount > 0 &&
        closingBalance > tierCapAmount) {
      // Tier 1: Balance up to tier cap
      final tier1Gross = tierCapAmount * (annualRate / 365.0);
      // Tier 2: Excess balance above tier cap
      final excessBalance = closingBalance - tierCapAmount;
      final tier2Rate = secondaryInterestRate ?? annualRate;
      final tier2Gross = excessBalance * (tier2Rate / 365.0);
      grossInterest = tier1Gross + tier2Gross;
    } else {
      grossInterest = closingBalance * (annualRate / 365.0);
    }

    final taxDeducted = grossInterest * withholdingTaxRate;
    final netInterest = grossInterest - taxDeducted;

    return InterestCalculationResult(
      closingBalance: closingBalance,
      grossInterest: grossInterest,
      taxDeducted: taxDeducted,
      netInterest: netInterest,
    );
  }

  /// Calculates missed days between [startDate] and [endDate] (inclusive).
  ///
  /// Returns a list of daily interest entries ready to be logged to `interest_ledger`.
  static List<InterestCalculationResult> calculateMissedDays({
    required Account account,
    required AccountInterestConfig config,
    required DateTime startDate,
    required DateTime endDate,
    required double runningBalance,
  }) {
    final results = <InterestCalculationResult>[];
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final target = DateTime(endDate.year, endDate.month, endDate.day);

    while (current.isBefore(target) || current.isAtSameMomentAs(target)) {
      final dailyResult = calculateDailyInterest(
        closingBalance: runningBalance,
        annualRate: config.interestRate,
        withholdingTaxRate: config.withholdingTaxRate,
        tierCapAmount: config.tierCapAmount,
        secondaryInterestRate: config.secondaryInterestRate,
      );
      results.add(dailyResult);
      current = current.add(const Duration(days: 1));
    }

    return results;
  }
}
