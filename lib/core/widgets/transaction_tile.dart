// lib/core/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';
import 'package:pitaka/core/utils/currency_formatter.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel transaction;
  final bool showDate;
  final bool showTime;
  final bool showDivider;
  final String currency;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.showDate = false,
    this.showTime = false,
    this.showDivider = false,
    this.currency = 'PHP',
    this.onTap,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _isPressed = false;

  void _handleTapDown(_) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.amount > 0;
    final color = isIncome ? const Color(0xFF2E9F5D) : const Color(0xFFD64545);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: _isPressed ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: widget.showDivider
                ? Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.01 : 0.03),
                blurRadius: _isPressed ? 2 : 6,
                offset: Offset(0, _isPressed ? 1 : 2),
              ),
            ],
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
                      widget.transaction.category ?? 'Uncategorized',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    if (widget.showDate || widget.showTime) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.showDate
                            ? DateFormat(
                                'MMM d, y · h:mm a',
                              ).format(widget.transaction.createdAt)
                            : DateFormat(
                                'h:mm a',
                              ).format(widget.transaction.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    if (widget.transaction.note != null &&
                        widget.transaction.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.transaction.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : ''}${formatMoney(widget.transaction.amount.abs(), widget.currency)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
