// lib/screens/dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/update_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_formatter.dart';
import '../account/account_card.dart';
import 'update_dialog.dart';
import '../../core/widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final equityAsync = ref.watch(totalEquityByCurrencyProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    // ref.listen fires as a side effect (not during build) whenever
    ref.listen<AsyncValue<Map<String, dynamic>?>>(updateCheckProvider, (
      previous,
      next,
    ) {
      final updateInfo = next.value;
      if (updateInfo != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(updateInfo: updateInfo),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5), // Background token
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Good day',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // The new manual update button
                        IconButton(
                          icon: const Icon(Icons.system_update, size: 20),
                          color: Colors.grey.shade600,
                          onPressed: () async {
                            final updateService = ref.read(
                              updateServiceProvider,
                            );

                            final updateInfo = await updateService
                                .checkForUpdate();

                            if (!context.mounted) return;

                            if (updateInfo != null) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) =>
                                    UpdateDialog(updateInfo: updateInfo),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your app is up to date!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const Text(
                      'Your Wallet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _EquityBadge(equityAsync: equityAsync),
                  ],
                ),
              ),
            ),

            // Accounts strip
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Accounts',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No accounts yet — add one to see it here.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  // Sorts accounts with balance from highest to lowest
                  final sortedAccounts = [...accounts]
                    ..sort((a, b) => b.balance.compareTo(a.balance));

                  return SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sortedAccounts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 160,
                          child: AccountCard(account: sortedAccounts[index]),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 190,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Error loading accounts: $err'),
                ),
              ),
            ),

            // Divider between accounts and transactions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable transaction stack
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No transactions yet.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  );
                }

                final grouped = _groupByDate(transactions);
                final dateKeys = grouped.keys.toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final dateKey = dateKeys[index];
                    final dayTransactions = grouped[dateKey]!;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateKey,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...dayTransactions.map(
                            (t) => TransactionTile(transaction: t),
                          ),
                        ],
                      ),
                    );
                  }, childCount: dateKeys.length),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading transactions: $err'),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> transactions,
  ) {
    final sorted = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final Map<String, List<TransactionModel>> grouped = {};

    for (final t in sorted) {
      final label = _dateLabel(t.createdAt);
      grouped.putIfAbsent(label, () => []).add(t);
    }
    return grouped;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }
}

/// Floating equity badge — square shape with rounded corners.
/// Shows totals grouped per currency (never blended).
class _EquityBadge extends StatelessWidget {
  final AsyncValue<Map<String, double>> equityAsync;

  const _EquityBadge({required this.equityAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F8A5B), // Primary Malachite Green
        borderRadius: BorderRadius.circular(20), // squared, rounded corners
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F8A5B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL EQUITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          equityAsync.when(
            data: (totals) {
              if (totals.isEmpty) {
                return const Text(
                  '—',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }
              // Primary currency (PHP if present) shown large;
              final sortedEntries = totals.entries.toList()
                ..sort((a, b) => a.key == 'PHP' ? -1 : 1);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMoney(
                      sortedEntries.first.value,
                      sortedEntries.first.key,
                    ),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (sortedEntries.length > 1) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: sortedEntries.skip(1).map((entry) {
                        return Text(
                          formatMoney(entry.value, entry.key),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            },
            loading: () => const SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            error: (err, stack) =>
                const Text('—', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
