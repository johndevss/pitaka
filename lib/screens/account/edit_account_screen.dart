import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../utils/currency_formatter.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final Account account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Toggle between Transaction History View and Edit View
  bool _isEditing = false;

  late Account _currentAccount;
  late TextEditingController _nameController;
  late TextEditingController _interestController;

  late bool _hasInterest;
  late String _selectedInterestType;

  @override
  void initState() {
    super.initState();

    // Pre-fill edit form controllers
    _currentAccount = widget.account;
    _nameController = TextEditingController(text: widget.account.name ?? '');
    _hasInterest = widget.account.interestType != 'none';
    _selectedInterestType = _hasInterest
        ? widget.account.interestType
        : 'daily';
    _interestController = TextEditingController(
      text: widget.account.interestRate != null
          ? widget.account.interestRate.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final dao = ref.read(accountDaoProvider);
    final accountType = widget.account.type;

    final updatedAccount = _currentAccount.copyWith(
      name: _nameController.text.trim(),
      interestRate:
          ((accountType == 'bank' || accountType == 'e-wallet') &&
              _hasInterest &&
              _interestController.text.trim().isNotEmpty)
          ? double.tryParse(_interestController.text)
          : null,
      interestType:
          ((accountType == 'bank' || accountType == 'e-wallet') && _hasInterest)
          ? _selectedInterestType
          : 'none',
    );

    await dao.updateAccount(updatedAccount);

    _invalidateProviders();

    setState(() {
      _currentAccount = updatedAccount;
      _isEditing = false; // Return to transactions view after saving
    });
  }

  Future<void> _deleteAccount() async {
    if (widget.account.id == null) return;

    final dao = ref.read(accountDaoProvider);
    await dao.deleteAccount(widget.account.id!);

    _invalidateProviders();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _invalidateProviders() {
    ref.invalidate(accountsProvider);
    ref.invalidate(totalEquityByCurrencyProvider);
    ref.invalidate(allTransactionsProvider);
    if (widget.account.id != null) {
      ref.invalidate(accountBalanceProvider(widget.account.id!));
      ref.invalidate(transactionsByAccountProvider(widget.account.id!));
    }
  }

  void _showDeleteConfirmationModal() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Account?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${_currentAccount.name ?? widget.account.provider}"? This action cannot be undone.',
            style: const TextStyle(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteAccount();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInterestTypeChip(String value, String label) {
    final isSelected = _selectedInterestType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedInterestType = value;
        });
      },
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(accountBalanceProvider(_currentAccount.id!));
    final transactionsAsync = ref.watch(
      transactionsByAccountProvider(_currentAccount.id!),
    );
    final isInterestEligible =
        _currentAccount.type == 'bank' || _currentAccount.type == 'e-wallet';

    final displayName =
        _currentAccount.name != null && _currentAccount.name!.isNotEmpty
        ? _currentAccount.name!
        : _currentAccount.provider.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Account' : displayName),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_outlined),
            tooltip: _isEditing ? 'Cancel Editing' : 'Edit Account',
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- FLOATING BALANCE BADGE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F8A5B),
                borderRadius: BorderRadius.circular(20),
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
                    'CURRENT BALANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  balanceAsync.when(
                    data: (balance) => Text(
                      formatMoney(balance, widget.account.currency),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    error: (err, stack) => const Text(
                      '—',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- VIEW 1: TRANSACTIONS LIST (Default) ---
            if (!_isEditing) ...[
              Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'No transactions recorded for this account yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return _AccountTransactionTile(transaction: t);
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Text('Error loading transactions: $err'),
              ),
            ],

            // --- VIEW 2: EDIT FORM ---
            if (_isEditing) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname (Optional)',
                        hintText: 'e.g. Savings, My Wallet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (isInterestEligible) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'This account earns interest',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _hasInterest,
                        onChanged: (value) {
                          setState(() {
                            _hasInterest = value;
                            if (!value) {
                              _interestController.clear();
                            }
                          });
                        },
                      ),
                      if (_hasInterest) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Crediting Frequency',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInterestTypeChip('daily', 'Daily'),
                            _buildInterestTypeChip('annual', 'Annual'),
                            _buildInterestTypeChip('quarterly', 'Quarterly'),
                            _buildInterestTypeChip('other', 'Other'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _interestController,
                          decoration: const InputDecoration(
                            labelText: 'Interest Rate per Year',
                            suffixText: '%',
                            hintText: 'e.g. 4.0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (!_hasInterest) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a rate, or turn off interest above';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _saveChanges,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showDeleteConfirmationModal,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text(
                        'Delete Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper tile widget for rendering individual account transactions
class _AccountTransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _AccountTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final color = isIncome ? const Color(0xFF2E9F5D) : const Color(0xFFD64545);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  transaction.category ?? 'Uncategorized',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                Text(
                  DateFormat('MMM d, y · h:mm a').format(transaction.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (transaction.note != null &&
                    transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : ''}${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
