// lib/screens/expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/features/account/controllers/account_providers.dart';
import 'package:pitaka/features/transaction/controllers/transaction_providers.dart';
import 'package:pitaka/features/category/controllers/category_providers.dart';
import 'package:pitaka/features/category/models/category.dart'
    show CategoryType;
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';
import 'package:pitaka/core/utils/currency_formatter.dart';
import 'package:pitaka/core/utils/category_icons.dart';
import 'package:pitaka/core/widgets/numeric_keypad.dart';
import 'package:pitaka/core/widgets/animated_toast.dart';

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

    final signedAmount = _isExpense ? -_amountValue : _amountValue;
    final transaction = TransactionModel(
      accountId: _selectedAccount!.id!,
      amount: signedAmount,
      category: _selectedCategory,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref
        .read(transactionsControllerProvider.notifier)
        .addTransaction(transaction);

    final currency = _selectedAccount?.currency ?? 'PHP';
    final formattedAmount = formatMoney(_amountValue, currency);

    if (!mounted) return;

    // Trigger the floating pill just before we pop the screen!
    _showSuccessToast(context, formattedAmount, _selectedCategory);

    Navigator.of(context).pop();
  }

  void _showSuccessToast(
    BuildContext context,
    String amountText,
    String? category,
  ) {
    final message = category != null
        ? '${_isExpense ? 'Expense' : 'Income'} saved\n$amountText in $category'
        : '${_isExpense ? 'Expense' : 'Income'} saved\n$amountText';

    showSuccessToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(
      categoriesByTypeProvider(
        _isExpense ? CategoryType.expense : CategoryType.income,
      ),
    );
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
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No ${_isExpense ? 'expense' : 'income'} categories yet — add some in Manage > Categories',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final color = colorFromHex(cat.colorHex);
                      final isSelected = _selectedCategory == cat.name;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = isSelected ? null : cat.name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconForKey(cat.iconKey),
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
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
                  );
                },
                loading: () => const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),

            const Spacer(),

            // Numeric keypad
            NumericKeypad(onKeyTap: _onKeyTap),

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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.asset(
                                          'assets/icons/institutions/${acc.iconKey}.png',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.account_balance_wallet,
                                                  size: 18,
                                                  color: Colors.grey.shade400,
                                                );
                                              },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
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
                                      ),
                                    ],
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
