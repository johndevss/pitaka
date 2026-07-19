import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_providers.dart';
import '../../models/account.dart';
import '../../data/institutions.dart';
import '../../utils/currency_formatter.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _interestController = TextEditingController();
  
  late TabController _tabController;
  Institution? _selectedInstitution;
  bool _showProviderError = false;

  bool _hasInterest = false;
  String _selectedInterestType = 'daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedInstitution = null;
          _nameController.clear();
          _hasInterest = false;
          _selectedInterestType = 'daily';
          _interestController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _interestController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Institution> _getFilteredInstitutions() {
    if (_tabController.index == 0) {
      return supportedInstitutions.where((i) => i.type == 'e-wallet').toList();
    } else {
      return supportedInstitutions.where((i) => i.type == 'bank').toList();
    }
  }

  String _getAccountTypeFromIndex(int index) {
    switch (index) {
      case 0: return 'e-wallet';
      case 1: return 'bank';
      case 2: return 'credit';
      default: return 'e-wallet';
    }
  }

  Future<void> _submit() async {
    // Check custom provider selection first
    if (_selectedInstitution == null) {
      setState(() {
        _showProviderError = true;
      });
    }

    // Run standard text field validations
    final isFormValid = _formKey.currentState!.validate();

    // Stop submission if either check fails
    if (_selectedInstitution == null || !isFormValid) return;

    final dao = ref.read(accountDaoProvider); 
    final accountType = _getAccountTypeFromIndex(_tabController.index);

    await dao.insertAccount(Account(
      name: _nameController.text.trim(), 
      type: accountType,
      provider: _selectedInstitution?.iconKey ?? 'custom', 
      balance: double.parse(_balanceController.text),
      iconKey: _selectedInstitution?.iconKey,
      currency: _selectedInstitution?.currency ?? 'PHP',
      interestRate: ((accountType == 'bank' || accountType == 'e-wallet') && _hasInterest && _interestController.text.trim().isNotEmpty)
        ? double.tryParse(_interestController.text)
        : null,
      interestType: ((accountType == 'bank' || accountType == 'e-wallet') && _hasInterest)
        ? _selectedInterestType
        : 'none',
      createdAt: DateTime.now(),
    ));

    ref.invalidate(accountsProvider);

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
    final filteredInstitutions = _getFilteredInstitutions();
    final currentCurrency = _selectedInstitution?.currency ?? 'PHP';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Wallet'),
            Tab(icon: Icon(Icons.savings), text: 'Savings'),
            Tab(icon: Icon(Icons.credit_card), text: 'Credit'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Provider',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredInstitutions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filteredInstitutions.length) {
                      return GestureDetector(
                        onTap: () {
                          // TODO: Implement your custom provider modal later
                          print("Custom provider clicked");
                        },
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 24,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final institution = filteredInstitutions[index];
                    final isSelected = _selectedInstitution == institution;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedInstitution = institution;
                          _nameController.text = institution.name;
                          _showProviderError = false;
                        });
                      },
                      child: Container(
                        width: 85,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/icons/institutions/${institution.iconKey}.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _tabController.index == 0 
                                        ? Icons.account_balance_wallet 
                                        : Icons.account_balance,
                                    size: 30,
                                    color: Colors.grey.shade400,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              institution.name,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showProviderError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    'Please pick a provider',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname (Optional)',
                  hintText: 'e.g. Savings, My Wallet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: _tabController.index == 2 
                      ? 'Current Outstanding Balance (Debt)' 
                      : 'Starting Balance',
                  prefixText: '${currencySymbol(currentCurrency)} ',
                  border: const OutlineInputBorder(),
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
              
              if (_tabController.index == 0 || _tabController.index == 1) ...[
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Save Account',
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