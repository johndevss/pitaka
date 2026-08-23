import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';
import 'package:pitaka/features/transaction/controllers/transaction_providers.dart';
import 'package:pitaka/core/utils/currency_formatter.dart';
import 'package:pitaka/core/widgets/transaction_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF5F7F5),
        elevation: 0,
        centerTitle: false,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions recorded yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final summaries = _groupTransactionsByDate(transactions);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return _DailyTransactionGroup(summary: summary);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading history: $err')),
      ),
    );
  }

  /// Groups transactions by date and computes daily summaries
  List<_DailySummary> _groupTransactionsByDate(
    List<TransactionModel> transactions,
  ) {
    final sorted = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Map<String, List<TransactionModel>> groupedMap = {};

    for (final t in sorted) {
      final key = DateFormat('yyyy-MM-dd').format(t.createdAt);
      groupedMap.putIfAbsent(key, () => []).add(t);
    }

    return groupedMap.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      return _DailySummary(date: date, transactions: entry.value);
    }).toList();
  }
}

/// Helper model to hold date, list of transactions, and daily totals
class _DailySummary {
  final DateTime date;
  final List<TransactionModel> transactions;

  _DailySummary({required this.date, required this.transactions});

  double get totalEarned => transactions
      .where((t) => t.amount > 0)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalSpent => transactions
      .where((t) => t.amount < 0)
      .fold(0.0, (sum, t) => sum + t.amount.abs());
}

/// Card component representing a single day's transaction group
class _DailyTransactionGroup extends StatelessWidget {
  final _DailySummary summary;

  const _DailyTransactionGroup({required this.summary});

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Header section: Date + Earned/Spent Badges
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateLabel(summary.date),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    Text(
                      DateFormat('EEE, MMM d').format(summary.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Total Earned badge
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E9F5D).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_downward_rounded,
                              size: 14,
                              color: Color(0xFF2E9F5D),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Earned: ${formatMoney(summary.totalEarned, 'PHP')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E9F5D),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Total Spent badge
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD64545).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                              color: Color(0xFFD64545),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Spent: ${formatMoney(summary.totalSpent, 'PHP')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD64545),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Individual Transactions List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: summary.transactions.map((t) {
                final isLast = t == summary.transactions.last;
                return TransactionTile(
                  transaction: t,
                  showTime: true,
                  showDivider: !isLast,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
