import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_providers.dart';
import '../../models/account.dart';
import '../../utils/currency_formatter.dart';
import 'account_card.dart';
import 'add_account_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddAccountScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Add Account',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text('No accounts yet. Tap + to add one.'),
            );
          }

          // Filter the accounts by type
          final eWallets = accounts.where((a) => a.type == 'e-wallet').toList();
          final banks = accounts.where((a) => a.type == 'bank').toList();
          final creditCards = accounts
              .where((a) => a.type == 'credit')
              .toList();

          // Build the scrollable list with our new _CategoryHeader
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              if (eWallets.isNotEmpty) ...[
                _CategoryHeader(title: 'E-Wallets', accounts: eWallets),
                const SizedBox(height: 12),
                _buildAccountGrid(eWallets),
                const SizedBox(height: 24),
              ],

              if (banks.isNotEmpty) ...[
                _CategoryHeader(title: 'Bank Accounts', accounts: banks),
                const SizedBox(height: 12),
                _buildAccountGrid(banks),
                const SizedBox(height: 24),
              ],

              if (creditCards.isNotEmpty) ...[
                _CategoryHeader(title: 'Credit Cards', accounts: creditCards),
                const SizedBox(height: 12),
                _buildAccountGrid(creditCards),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // Helper widget to build the grid for each section
  Widget _buildAccountGrid(List<Account> sectionAccounts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: sectionAccounts.length,
      itemBuilder: (context, index) {
        return AccountCard(account: sectionAccounts[index]);
      },
    );
  }
}

// Displays the category title on the left and the total sum(s) on the right.
class _CategoryHeader extends ConsumerWidget {
  final String title;
  final List<Account> accounts;

  const _CategoryHeader({required this.title, required this.accounts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, double> totals = {};
    bool isLoading = false;

    // Loop through each account in this specific category group
    for (final account in accounts) {
      if (account.id == null) continue;

      // Watch the computed balance provider for this specific account
      final balanceAsync = ref.watch(accountBalanceProvider(account.id!));

      balanceAsync.when(
        data: (balance) {
          final currency = account.currency;
          // Add the balance to the correct currency bucket
          totals[currency] = (totals[currency] ?? 0) + balance;
        },
        loading: () => isLoading = true,
        error: (_, _) {},
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // Show a small loader while calculating, otherwise show the sums
        if (isLoading)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (totals.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: totals.entries.map((entry) {
              return Text(
                formatMoney(entry.value, entry.key),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary, // Uses the Malachite Green
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
