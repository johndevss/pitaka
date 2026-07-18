// lib/screens/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/account_providers.dart';
import '../models/account.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text('No accounts yet. Tap + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _AccountTile(account: account);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // lets the sheet resize when keyboard opens
      builder: (context) => const _AddAccountSheet(),
    );
  }
}

// Shows a single account row, and reads its computed balance
// (starting balance + all transactions) via accountBalanceProvider.
class _AccountTile extends ConsumerWidget {
  final Account account;

  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id!));

    return ListTile(
      leading: CircleAvatar(
        child: Icon(_iconForType(account.type)),
      ),
      title: Text(account.name),
      subtitle: Text(account.type),
      trailing: balanceAsync.when(
        data: (balance) => Text(
          '₱${balance.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (err, stack) => const Text('—'),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'e-wallet':
        return Icons.phone_iphone;
      case 'credit':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

// The add-account form, shown inside the bottom sheet.
class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet();

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'e-wallet';

  final _typeOptions = const ['bank', 'e-wallet', 'credit', 'cash'];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final dao = ref.read(accountDaoProvider);

    await dao.insertAccount(Account(
      name: _nameController.text.trim(),
      type: _selectedType,
      balance: double.parse(_balanceController.text),
      createdAt: DateTime.now(),
    ));

    // Tell Riverpod the accounts list is stale, so it re-fetches
    // and the Accounts screen updates automatically.
    ref.invalidate(accountsProvider);

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Pushes the sheet up above the keyboard when it's open
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Account', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'e.g. BPI Savings, GCash',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _typeOptions
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Starting balance',
                prefixText: '₱ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a starting balance';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Add Account'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}