// lib/screens/expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/account_providers.dart';
import '../providers/transaction_providers.dart';
import '../models/account.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

// Quick category shortcuts — expand this list as needed.
// icon + label only; category string saved is the label.
const List<_CategoryOption> _quickCategories = [
  _CategoryOption(
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFD9A441),
  ),
  _CategoryOption(
    label: 'Transport',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF1F8A5B),
  ),
  _CategoryOption(
    label: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFD64545),
  ),
  _CategoryOption(
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFF3AA76D),
  ),
];

class ExpenseScreen extends ConsumerStatefulWidget {
  final bool initialIsExpense;

  const ExpenseScreen({super.key, this.initialIsExpense = true});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  String _amountInput = '0';
  final _noteController = TextEditingController();

  Account? _selectedAccount;
  String? _selectedCategory;
  late bool _isExpense;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialIsExpense;
  }

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

      // Prevent more than 2 decimal digits
      if (_amountInput.contains('.')) {
        final parts = _amountInput.split('.');
        if (parts.length > 1 && parts[1].length >= 2) return;
      }

      _amountInput = _amountInput == '0' ? key : _amountInput + key;
    });
  }

  double get _amountValue => double.tryParse(_amountInput) ?? 0.0;

  Future<void> _save() async {
    if (_amountValue <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an amount first')));
      return;
    }
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick an account')));
      return;
    }

    final dao = ref.read(transactionDaoProvider);
    final signedAmount = _isExpense ? -_amountValue : _amountValue;

    // NOTE: assumes TransactionModel's constructor mirrors Account's pattern
    // (id nullable, createdAt required). Adjust field names here if
    // transaction_model.dart differs from this assumption.
    await dao.insertTransaction(
      TransactionModel(
        accountId: _selectedAccount!.id!,
        amount: signedAmount,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );

    // Invalidate every provider whose data this transaction affects.
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(todayTransactionsProvider);
    ref.invalidate(accountBalanceProvider(_selectedAccount!.id!));
    ref.invalidate(totalEquityByCurrencyProvider);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final currency = _selectedAccount?.currency ?? 'PHP';

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
        title: Text(
          _isExpense ? 'New Expense' : 'New Income',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
        centerTitle: true,
        actions: [
          // Toggle expense/income
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(
                _isExpense
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: _isExpense
                    ? const Color(0xFFD64545)
                    : const Color(0xFF2E9F5D),
              ),
              onPressed: () => setState(() => _isExpense = !_isExpense),
              tooltip: 'Switch to ${_isExpense ? 'income' : 'expense'}',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Amount display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        'NOTE',
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
                        hintText: 'e.g. Lunch, Grab ride, groceries',
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

            const SizedBox(height: 18),

            // Category chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CATEGORY (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _quickCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _quickCategories[index];
                  final isSelected = _selectedCategory == cat.label;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = isSelected ? null : cat.label;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? cat.color : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: const Color(0xFF222222),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // Numeric keypad
            _NumericKeypad(onKeyTap: _onKeyTap),

            // Account selector + Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: accountsAsync.when(
                      data: (accounts) {
                        // Default to first account once loaded, if none picked yet.
                        if (_selectedAccount == null && accounts.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _selectedAccount = accounts.first);
                            }
                          });
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Account>(
                              isExpanded: true,
                              value: _selectedAccount,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              items: accounts.map((acc) {
                                return DropdownMenuItem(
                                  value: acc,
                                  child: Text(
                                    acc.name?.isNotEmpty == true
                                        ? acc.name!
                                        : acc.provider,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (acc) =>
                                  setState(() => _selectedAccount = acc),
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F8A5B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isExpense ? 'Save Expense' : 'Save Income',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryOption({
    required this.label,
    required this.icon,
    required this.color,
  });
}

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
