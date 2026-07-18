// lib/data/institutions.dart

class Institution {
  final String name;
  final String iconKey;
  final String type;

  const Institution({
    required this.name,
    required this.iconKey,
    required this.type,
  });
}

const List<Institution> supportedInstitutions = [
  Institution(name: 'GCash', iconKey: 'gcash', type: 'e-wallet'),
  Institution(name: 'Maya', iconKey: 'maya', type: 'e-wallet'),
  Institution(name: 'Maribank', iconKey: 'maribank', type: 'e-wallet'),
  Institution(name: 'GrabPay', iconKey: 'grabpay', type: 'e-wallet'),
  Institution(name: 'ShopeePay', iconKey: 'shopeepay', type: 'e-wallet'),
  Institution(name: 'BPI', iconKey: 'bpi', type: 'bank'),
  Institution(name: 'BDO', iconKey: 'bdo', type: 'bank'),
  Institution(name: 'Metrobank', iconKey: 'metrobank', type: 'bank'),
  Institution(name: 'UnionBank', iconKey: 'unionbank', type: 'bank'),
  Institution(name: 'Landbank', iconKey: 'landbank', type: 'bank'),
  Institution(name: 'RCBC', iconKey: 'rcbc', type: 'bank'),
];