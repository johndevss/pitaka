// lib/core/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool showDate;
  final bool showTime;
  final bool showDivider;
  final String currency;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.showDate = false,
    this.showTime = false,
    this.showDivider = false,
    this.currency = 'PHP',
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final color = isIncome ? const Color(0xFF2E9F5D) : const Color(0xFFD64545);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: showDivider
            ? Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category ?? 'Uncategorized',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                if (showDate || showTime) ...[
                  const SizedBox(height: 2),
                  Text(
                    showDate
                        ? DateFormat(
                            'MMM d, y · h:mm a',
                          ).format(transaction.createdAt)
                        : DateFormat('h:mm a').format(transaction.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
                if (transaction.note != null &&
                    transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : ''}${formatMoney(transaction.amount.abs(), currency)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
