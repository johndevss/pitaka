// lib/screens/transfer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../providers/account_providers.dart';
import '../../models/account.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/transaction_providers.dart';
import '../../models/transaction_model.dart';
import '../../data/transaction_dao.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
  ),
);

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  String _amountInput = '0';
  final _noteController = TextEditingController();

  Account? _fromAccount;
  Account? _toAccount;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == 'backspace') {
        _amountInput = _amountInput.length > 1
            ? _amountInput.substring(0, _amountInput.length - 1)
            : '0';
        return;
      }
      if (key == '.') {
        if (!_amountInput.contains('.')) {
          _amountInput += '.';
        }
        return;
      }
      if (_amountInput.contains('.')) {
        final parts = _amountInput.split('.');
        if (parts.length > 1 && parts[1].length >= 2) return;
      }
      _amountInput = _amountInput == '0' ? key : _amountInput + key;
    });
  }

  double get _amountValue => double.tryParse(_amountInput) ?? 0.0;

  Future<void> _saveTransfer() async {
    if (_amountValue <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an amount first')));
      return;
    }
    if (_fromAccount == null || _toAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick both accounts')));
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot transfer to the same account')),
      );
      return;
    }

    final currentBalance = await ref.read(
      accountBalanceProvider(_fromAccount!.id!).future,
    );

    if (currentBalance < _amountValue) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: ${currencySymbol(_fromAccount!.currency)}${currentBalance.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    }

    final dao = ref.read(transactionDaoProvider);
    final now = DateTime.now();

    final customNote = _noteController.text.trim();
    final expenseNote = customNote.isEmpty
        ? 'Transfer to ${_toAccount!.name ?? _toAccount!.provider}'
        : customNote;
    final incomeNote = customNote.isEmpty
        ? 'Transfer from ${_fromAccount!.name ?? _fromAccount!.provider}'
        : customNote;

    // Create the deduction for the sender
    final expense = TransactionModel(
      accountId: _fromAccount!.id!,
      amount: -_amountValue, // Negative amount
      category: 'Transfer',
      note: expenseNote,
      createdAt: now,
    );

    // Create the addition for the receiver
    final income = TransactionModel(
      accountId: _toAccount!.id!,
      amount: _amountValue, // Positive amount
      category: 'Transfer',
      note: incomeNote,
      createdAt: now,
    );

    try {
      // fetch the LIVE balance right before transferring
      final currentBalance = await ref.read(
        accountBalanceProvider(_fromAccount!.id!).future,
      );

      // Pass currentBalance into transferFunds
      await dao.transferFunds(expense, income, currentBalance: currentBalance);

      logger.i(
        'Successfully transferred $_amountValue from ${_fromAccount!.name} to ${_toAccount!.name}',
      );

      // Invalidate providers so the UI (Dashboard & Accounts) updates immediately
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(todayTransactionsProvider);
      ref.invalidate(accountBalanceProvider(_fromAccount!.id!));
      ref.invalidate(accountBalanceProvider(_toAccount!.id!));
      ref.invalidate(totalEquityByCurrencyProvider);
      ref.invalidate(accountsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
    } on InsufficientBalanceException catch (e) {
      logger.w('Transfer blocked: insufficient balance');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: ${currencySymbol(_fromAccount!.currency)}${e.available.toStringAsFixed(2)}',
          ),
        ),
      );
    } catch (e, st) {
      logger.e('Transfer failed', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transfer failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final currency = _fromAccount?.currency ?? 'PHP';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F5),
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
          ),
        ),
        leadingWidth: 90,
        title: const Text(
          'Transfer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currencySymbol(currency),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _amountInput,
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            // From / To Account Selectors
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAccountDropdown(
                      label: 'FROM',
                      value: _fromAccount,
                      accountsAsync: accountsAsync,
                      onChanged: (acc) => setState(() => _fromAccount = acc),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAccountDropdown(
                      label: 'TO',
                      value: _toAccount,
                      accountsAsync: accountsAsync,
                      onChanged: (acc) => setState(() => _toAccount = acc),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Note field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'NOTE (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Savings deposit',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 10),
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Reusing your custom Keypad logic
            _NumericKeypad(onKeyTap: _onKeyTap),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveTransfer,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2D88D4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirm Transfer',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the Dropdowns clearly
  Widget _buildAccountDropdown({
    required String label,
    required Account? value,
    required AsyncValue<List<Account>> accountsAsync,
    required ValueChanged<Account?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.6,
            ),
          ),
          accountsAsync.when(
            data: (accounts) => DropdownButtonHideUnderline(
              child: DropdownButton<Account>(
                isExpanded: true,
                value: value,
                hint: const Text('Select', style: TextStyle(fontSize: 14)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc,
                    child: Text(
                      acc.name?.isNotEmpty == true ? acc.name! : acc.provider,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Keypad exactly as you had it
class _NumericKeypad extends StatelessWidget {
  final void Function(String key) onKeyTap;
  const _NumericKeypad({required this.onKeyTap});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'backspace'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _KeypadButton(
                      keyLabel: key,
                      onTap: () => onKeyTap(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String keyLabel;
  final VoidCallback onTap;
  const _KeypadButton({required this.keyLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBackspace = keyLabel == 'backspace';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Center(
            child: isBackspace
                ? Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                  )
                : Text(
                    keyLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
