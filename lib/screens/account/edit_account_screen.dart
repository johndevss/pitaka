import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../providers/account_providers.dart';
import '../../utils/currency_formatter.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  final Account account;

  const EditAccountScreen({super.key, required this.account});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _interestController;

  late bool _hasInterest;
  late String _selectedInterestType;

  @override
  void initState() {
    super.initState();

    // 1. Pre-fill text field with existing account nickname
    _nameController = TextEditingController(text: widget.account.name ?? '');

    // 2. Pre-fill interest settings
    _hasInterest = widget.account.interestType != 'none';
    _selectedInterestType = _hasInterest ? widget.account.interestType : 'daily';
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

    // Preserve provider, balance, currency, and update nickname & interest
    final updatedAccount = widget.account.copyWith(
      name: _nameController.text.trim(),
      interestRate: ((accountType == 'bank' || accountType == 'e-wallet') &&
              _hasInterest &&
              _interestController.text.trim().isNotEmpty)
          ? double.tryParse(_interestController.text)
          : null,
      interestType: ((accountType == 'bank' || accountType == 'e-wallet') && _hasInterest)
          ? _selectedInterestType
          : 'none',
    );

    await dao.updateAccount(updatedAccount);

    // Invalidate providers to force UI updates across screens
    ref.invalidate(accountsProvider);
    ref.invalidate(totalEquityByCurrencyProvider);
    if (widget.account.id != null) {
      ref.invalidate(accountBalanceProvider(widget.account.id!));
    }

    if (!mounted) return;
    Navigator.of(context).pop();
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
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read live balance for this account
    final balanceAsync = ref.watch(accountBalanceProvider(widget.account.id!));
    final isInterestEligible =
        widget.account.type == 'bank' || widget.account.type == 'e-wallet';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- FLOATING BALANCE BADGE (Dashboard style) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F8A5B), // Primary Malachite Green
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

              // --- NICKNAME FIELD ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname (Optional)',
                  hintText: 'e.g. Savings, My Wallet',
                  border: OutlineInputBorder(),
                ),
              ),

              // --- INTEREST SETTINGS ---
              if (isInterestEligible) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'This account earns interest',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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

              // --- SAVE BUTTON ---
              FilledButton(
                onPressed: _saveChanges,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}