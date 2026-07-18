// lib/screens/account/account_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_providers.dart';
import '../../models/account.dart';

class AccountCard extends ConsumerWidget {
  final Account account;

  const AccountCard({
    super.key, 
    required this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id!));
    final cardColor = _colorForType(account.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon badge + name, three-dot menu
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconForType(account.type), size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.more_horiz, size: 18, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            _subtitleForAccount(account),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),

          const Spacer(),

          // Bottom row: Balance label + value
          const Text(
            'BALANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          balanceAsync.when(
            data: (balance) => Text(
              '₱${balance.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            error: (err, stack) => const Text(
              '—',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'bank':
        return const Color(0xffd64545);
      case 'e-wallet':
        return const Color(0xff1f8a5b);
      case 'credit':
        return const Color(0xff3aa76d);
      case 'cash':
        return const Color(0xffd9a441);
      default:
        return const Color(0xff666666);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'e-wallet':
        return Icons.phone_iphone_rounded;
      case 'credit':
        return Icons.credit_card_rounded;
      case 'cash':
        return Icons.payments_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  String _subtitleForAccount(Account account) {
    final typeLabel = account.type == 'e-wallet'
        ? 'Debit'
        : account.type == 'credit'
            ? 'Credit'
            : account.type[0].toUpperCase() + account.type.substring(1);
    return '$typeLabel · PHP';
  }
}