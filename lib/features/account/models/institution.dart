// lib/features/account/models/institution.dart

enum InstitutionType { bank, eWallet, cash, creditCard, investment }

class DefaultInterestPreset {
  final double defaultRate;
  final String calcMode;
  final int payoutDay;
  final double withholdingTaxRate;
  final double? tierCapAmount;
  final double? secondaryInterestRate;

  const DefaultInterestPreset({
    required this.defaultRate,
    this.calcMode = 'daily_payout',
    this.payoutDay = 1,
    this.withholdingTaxRate = 0.20,
    this.tierCapAmount,
    this.secondaryInterestRate,
  });
}

class Institution {
  final String id;
  final String name;
  final InstitutionType type;
  final String iconKey;
  final String currency;
  final bool hasInterest;
  final DefaultInterestPreset? defaultInterest;

  const Institution({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    this.currency = 'PHP',
    this.hasInterest = false,
    this.defaultInterest,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'icon_key': iconKey,
    'default_currency': currency,
    'has_interest': hasInterest ? 1 : 0,
  };

  factory Institution.fromMap(Map<String, dynamic> map) {
    return Institution(
      id: map['id'] as String,
      name: map['name'] as String,
      type: InstitutionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => InstitutionType.bank,
      ),
      iconKey: map['icon_key'] as String,
      currency: map['default_currency'] as String? ?? 'PHP',
      hasInterest: (map['has_interest'] as int?) == 1,
    );
  }
}

class InstitutionRegistry {
  static const Map<String, Institution> _registry = {
    'cash': Institution(
      id: 'cash',
      name: 'Cash',
      type: InstitutionType.cash,
      iconKey: 'cash_on_hand',
    ),
    'gcash': Institution(
      id: 'gcash',
      name: 'GCash',
      type: InstitutionType.eWallet,
      iconKey: 'gcash',
    ),
    'maya': Institution(
      id: 'maya',
      name: 'Maya',
      type: InstitutionType.eWallet,
      iconKey: 'maya',
      hasInterest: true,
      defaultInterest: DefaultInterestPreset(
        defaultRate: 0.035,
        calcMode: 'daily_accrue_monthly_payout',
        payoutDay: 1,
      ),
    ),
    'maribank': Institution(
      id: 'maribank',
      name: 'Maribank',
      type: InstitutionType.bank,
      iconKey: 'maribank',
      hasInterest: true,
      defaultInterest: DefaultInterestPreset(
        defaultRate: 0.045,
        calcMode: 'daily_payout',
      ),
    ),
    'seabank': Institution(
      id: 'seabank',
      name: 'SeaBank',
      type: InstitutionType.bank,
      iconKey: 'seabank',
      hasInterest: true,
      defaultInterest: DefaultInterestPreset(
        defaultRate: 0.045,
        calcMode: 'daily_payout',
      ),
    ),
    'gotyme': Institution(
      id: 'gotyme',
      name: 'GoTyme',
      type: InstitutionType.bank,
      iconKey: 'gotyme',
      hasInterest: true,
      defaultInterest: DefaultInterestPreset(
        defaultRate: 0.040,
        calcMode: 'daily_accrue_monthly_payout',
        payoutDay: 1,
      ),
    ),
    'diskartech': Institution(
      id: 'diskartech',
      name: 'DiskarTech',
      type: InstitutionType.bank,
      iconKey: 'rcbc-diskartech',
      hasInterest: true,
      defaultInterest: DefaultInterestPreset(
        defaultRate: 0.065,
        calcMode: 'daily_payout',
        tierCapAmount: 50000,
        secondaryInterestRate: 0.030,
      ),
    ),
    'grabpay': Institution(
      id: 'grabpay',
      name: 'GrabPay',
      type: InstitutionType.eWallet,
      iconKey: 'grabpay',
    ),
    'shopeepay': Institution(
      id: 'shopeepay',
      name: 'ShopeePay',
      type: InstitutionType.eWallet,
      iconKey: 'shopeepay',
    ),
    'bpi': Institution(
      id: 'bpi',
      name: 'BPI',
      type: InstitutionType.bank,
      iconKey: 'bpi',
    ),
    'bdo': Institution(
      id: 'bdo',
      name: 'BDO',
      type: InstitutionType.bank,
      iconKey: 'bdo',
    ),
    'metrobank': Institution(
      id: 'metrobank',
      name: 'Metrobank',
      type: InstitutionType.bank,
      iconKey: 'metrobank',
    ),
    'unionbank': Institution(
      id: 'unionbank',
      name: 'UnionBank',
      type: InstitutionType.bank,
      iconKey: 'unionbank',
    ),
    'landbank': Institution(
      id: 'landbank',
      name: 'Landbank',
      type: InstitutionType.bank,
      iconKey: 'landbank',
    ),
    'rcbc': Institution(
      id: 'rcbc',
      name: 'RCBC',
      type: InstitutionType.bank,
      iconKey: 'rcbc',
    ),
    'bpi-banko': Institution(
      id: 'bpi-banko',
      name: 'BPI BanKo',
      type: InstitutionType.eWallet,
      iconKey: 'bpi-banko',
    ),
  };

  static final Map<String, Institution> _customRegistry = {};

  static void registerCustom(Institution institution) {
    _customRegistry[institution.id.toLowerCase()] = institution;
  }

  static void clearCustom() {
    _customRegistry.clear();
  }

  static Institution? getById(String id) {
    final key = id.toLowerCase();
    return _registry[key] ?? _customRegistry[key];
  }

  static List<Institution> get all => [
    ..._registry.values,
    ..._customRegistry.values,
  ];
  static List<Institution> get banks =>
      all.where((i) => i.type == InstitutionType.bank).toList();
  static List<Institution> get eWallets =>
      all.where((i) => i.type == InstitutionType.eWallet).toList();
}
