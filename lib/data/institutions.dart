// lib/data/institutions.dart

class Institution {
  final String name;
  final String iconKey;
  final String currency;
  final String type;

  const Institution({
    required this.name,
    required this.iconKey,
    required this.currency,
    required this.type,
  });
}

const List<Institution> supportedInstitutions = [
  Institution(name: 'GCash', iconKey: 'gcash', currency: 'PHP', type: 'e-wallet'),
  Institution(name: 'Maya', iconKey: 'maya', currency: 'PHP', type: 'e-wallet'),
  Institution(name: 'Maribank', iconKey: 'maribank', currency: 'PHP', type: 'e-wallet'),
  Institution(name: 'GrabPay', iconKey: 'grabpay', currency: 'PHP', type: 'e-wallet'),
  Institution(name: 'ShopeePay', iconKey: 'shopeepay', currency: 'PHP', type: 'e-wallet'),
  Institution(name: 'BPI', iconKey: 'bpi', currency: 'PHP', type: 'bank'),
  Institution(name: 'BDO', iconKey: 'bdo', currency: 'PHP', type: 'bank'),
  Institution(name: 'Metrobank', iconKey: 'metrobank', currency: 'PHP', type: 'bank'),
  Institution(name: 'UnionBank', iconKey: 'unionbank', currency: 'PHP', type: 'bank'),
  Institution(name: 'Landbank', iconKey: 'landbank', currency: 'PHP', type: 'bank'),
  Institution(name: 'RCBC', iconKey: 'rcbc', currency: 'PHP', type: 'bank'),
];