// lib/screens/expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/features/account/controllers/account_providers.dart';
import 'package:pitaka/features/transaction/controllers/transaction_providers.dart';
import 'package:pitaka/features/transaction/data/transaction_dao.dart';
import 'package:pitaka/features/category/controllers/category_providers.dart';
import 'package:pitaka/features/category/models/category.dart'
    show CategoryType;
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';
import 'package:pitaka/core/utils/currency_formatter.dart';
import 'package:pitaka/core/utils/category_icons.dart';
import 'package:pitaka/core/widgets/numeric_keypad.dart';
import 'package:pitaka/core/widgets/animated_toast.dart';
import 'package:pitaka/core/widgets/pull_to_dismiss_wrapper.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  final bool initialIsExpense;
  final String? heroTag;
  final TransactionModel? transaction;

  const ExpenseScreen({
    super.key,
    this.initialIsExpense = true,
    this.heroTag,
    this.transaction,
  });

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
    final transaction = widget.transaction;
    _isExpense = transaction != null
        ? transaction.amount < 0
        : widget.initialIsExpense;
    if (transaction != null) {
      _amountInput = transaction.amount
          .abs()
          .toStringAsFixed(transaction.amount.abs() % 1 == 0 ? 0 : 2)
          .replaceFirst(RegExp(r'\.00$'), '');
      _noteController.text = transaction.note ?? '';
      _selectedCategory = transaction.category;
    }
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
    final original = widget.transaction;
    final transaction = original == null
        ? TransactionModel(
            accountId: _selectedAccount!.id!,
            amount: signedAmount,
            category: _selectedCategory,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            createdAt: DateTime.now(),
          )
        : original.copyWith(
            accountId: _selectedAccount!.id!,
            amount: signedAmount,
            category: _selectedCategory,
            categoryId: null,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );

    try {
      if (original == null) {
        await ref
            .read(transactionsControllerProvider.notifier)
            .addTransaction(transaction);
      } else {
        await ref
            .read(transactionsControllerProvider.notifier)
            .updateTransaction(
              transaction,
              previousAccountId: original.accountId,
            );
      }
    } on InsufficientBalanceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: ${currencySymbol(_selectedAccount!.currency)}${e.available.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transaction update failed: $e')));
      return;
    }

    final currency = _selectedAccount?.currency ?? 'PHP';
    final formattedAmount = formatMoney(_amountValue, currency);

    if (!mounted) return;
    showSuccessToast(
      context,
      original == null
          ? '${_isExpense ? 'Expense' : 'Income'} saved\n$formattedAmount in ${_selectedCategory ?? 'Uncategorized'}'
          : 'Transaction updated\n$formattedAmount',
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final transaction = widget.transaction;
    if (transaction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          'This will reverse ${formatMoney(transaction.amount.abs(), _selectedAccount?.currency ?? 'PHP')} from its account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(transactionsControllerProvider.notifier)
        .deleteTransaction(transaction.id!, accountId: transaction.accountId);
    if (!mounted) return;
    showSuccessToast(context, 'Transaction deleted');
    Navigator.of(context).pop();
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

    return PullToDismissWrapper(
      child: Scaffold(
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
          actions: widget.transaction == null
              ? null
              : [
                  IconButton(
                    tooltip: 'Delete transaction',
                    onPressed: _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFD64545),
                    ),
                  ),
                ],
          title: Text(
            widget.transaction == null
                ? (_isExpense ? 'New Expense' : 'New Income')
                : 'Edit Transaction',
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
                                color: isSelected
                                    ? color
                                    : Colors.grey.shade200,
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
                          if (_selectedAccount == null && accounts.isNotEmpty) {
                            final original = widget.transaction;
                            if (original == null) {
                              _selectedAccount = accounts.first;
                            } else {
                              for (final account in accounts) {
                                if (account.id == original.accountId) {
                                  _selectedAccount = account;
                                  break;
                                }
                              }
                            }
                          }
                          final selectedValue =
                              accounts.contains(_selectedAccount)
                              ? _selectedAccount
                              : (accounts.isNotEmpty ? accounts.first : null);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Account>(
                                isExpanded: true,
                                value: selectedValue,
                                hint: const Text(
                                  'Select Account',
                                  style: TextStyle(fontSize: 14),
                                ),
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.asset(
                                            'assets/icons/institutions/${acc.iconKey}.png',
                                            width: 24,
                                            height: 24,
                                            cacheWidth: 48,
                                            cacheHeight: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons
                                                        .account_balance_wallet,
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
                                                : acc.providerName,
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
                          widget.transaction == null
                              ? (_isExpense ? 'Save Expense' : 'Save Income')
                              : 'Save Changes',
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
      ),
    );
  }
}
