import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/account/models/account_interest_config.dart';
import 'package:pitaka/features/account/data/institutions.dart';
import 'package:pitaka/features/account/controllers/account_providers.dart';
import 'package:pitaka/features/transaction/controllers/transaction_providers.dart';
import 'package:pitaka/core/utils/currency_formatter.dart';
import 'package:pitaka/core/widgets/transaction_tile.dart';
import 'package:pitaka/core/widgets/interest_type_selector.dart';
import 'package:pitaka/features/account/presentation/widgets/account_card.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final Account account;
  final String? heroTag;

  const AccountDetailsScreen({super.key, required this.account, this.heroTag});

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
    _hasInterest =
        widget.account.interestRate != null && widget.account.interestRate! > 0;
    _selectedInterestType = _hasInterest
        ? (widget.account.interestType ?? 'daily')
        : 'daily';

    final ratePercent = widget.account.interestRate != null
        ? (widget.account.interestRate! * 100.0)
        : null;
    _interestController = TextEditingController(
      text: ratePercent != null
          ? ratePercent.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
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

    final accountType = widget.account.type;
    final updatedAccount = _currentAccount.copyWith(
      name: _nameController.text.trim(),
    );

    if ((accountType == 'bank' || accountType == 'e-wallet') && _hasInterest) {
      final ratePercent =
          double.tryParse(_interestController.text.trim()) ?? 0.0;
      final rateDecimal = ratePercent / 100.0;

      final inst = widget.account.institutionId != null
          ? InstitutionRegistry.getById(widget.account.institutionId!)
          : null;
      final preset = inst?.defaultInterest;

      final config = AccountInterestConfig(
        accountId: _currentAccount.id!,
        interestRate: rateDecimal,
        calcMode: _selectedInterestType == 'daily'
            ? 'daily_payout'
            : 'daily_accrue_monthly_payout',
        payoutFrequency: _selectedInterestType == 'daily' ? 'daily' : 'monthly',
        payoutDay: preset?.payoutDay ?? 1,
        withholdingTaxRate: preset?.withholdingTaxRate ?? 0.20,
        tierCapAmount: preset?.tierCapAmount,
        secondaryInterestRate: preset?.secondaryInterestRate,
        autoPost: true,
      );

      await ref
          .read(accountsControllerProvider.notifier)
          .updateAccountWithConfig(updatedAccount, config);
    } else {
      await ref
          .read(accountsControllerProvider.notifier)
          .updateAccountWithConfig(updatedAccount, null);
    }

    // Refresh current account from controller state
    final accounts = ref.read(accountsControllerProvider).value ?? [];
    final refreshed = accounts.firstWhere(
      (a) => a.id == _currentAccount.id,
      orElse: () => updatedAccount,
    );

    setState(() {
      _currentAccount = refreshed;
      _isEditing = false; // Return to transactions view after saving
    });
  }

  Future<void> _deleteAccount() async {
    if (widget.account.id == null) return;

    await ref
        .read(accountsControllerProvider.notifier)
        .deleteAccount(widget.account.id!);

    if (!mounted) return;
    Navigator.of(context).pop();
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
        : _currentAccount.providerName.toUpperCase();

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
            // --- FLOATING BALANCE BADGE (Matches AccountCard Hero) ---
            Hero(
              tag: widget.heroTag ?? 'card_card_${widget.account.id}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorForAccount(_currentAccount),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorForAccount(
                          _currentAccount,
                        ).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _currentAccount.iconKey != null
                                ? Image.asset(
                                    'assets/icons/institutions/${_currentAccount.iconKey}.png',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          iconForType(_currentAccount.type),
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                  )
                                : Icon(
                                    iconForType(_currentAccount.type),
                                    size: 18,
                                    color: Colors.white,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayNameForProvider(
                                _currentAccount.providerName,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_currentAccount.name != null &&
                          _currentAccount.name!.isNotEmpty) ...[
                        Text(
                          _currentAccount.name!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        subtitleForAccount(_currentAccount),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CURRENT BALANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return TransactionTile(
                        transaction: t,
                        showDate: true,
                        currency: widget.account.currency,
                      );
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
                        InterestTypeSelector(
                          selectedType: _selectedInterestType,
                          onChanged: (type) =>
                              setState(() => _selectedInterestType = type),
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
