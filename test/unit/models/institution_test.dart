// test/unit/models/institution_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/features/account/models/institution.dart';

void main() {
  group('Institution & InstitutionRegistry Tests', () {
    test(
      'InstitutionRegistry.getById returns correct institution case-insensitively',
      () {
        final seabank = InstitutionRegistry.getById('seabank');
        expect(seabank, isNotNull);
        expect(seabank!.name, equals('SeaBank'));
        expect(seabank.hasInterest, isTrue);
        expect(seabank.defaultInterest, isNotNull);
        expect(seabank.defaultInterest!.defaultRate, equals(0.045));
        expect(seabank.defaultInterest!.calcMode, equals('daily_payout'));

        final gotyme = InstitutionRegistry.getById('GOTYME');
        expect(gotyme, isNotNull);
        expect(gotyme!.name, equals('GoTyme'));
        expect(
          gotyme.defaultInterest!.calcMode,
          equals('daily_accrue_monthly_payout'),
        );
      },
    );

    test('InstitutionRegistry.getById returns null for invalid id', () {
      expect(InstitutionRegistry.getById('non_existent_bank'), isNull);
    });

    test('InstitutionRegistry filters banks and eWallets correctly', () {
      final banks = InstitutionRegistry.banks;
      expect(banks.every((b) => b.type == InstitutionType.bank), isTrue);
      expect(banks.any((b) => b.id == 'seabank'), isTrue);

      final eWallets = InstitutionRegistry.eWallets;
      expect(eWallets.every((e) => e.type == InstitutionType.eWallet), isTrue);
      expect(eWallets.any((e) => e.id == 'gcash'), isTrue);
    });

    test('DiskarTech has correct tiered interest preset', () {
      final diskartech = InstitutionRegistry.getById('diskartech');
      expect(diskartech, isNotNull);
      expect(diskartech!.defaultInterest, isNotNull);
      expect(diskartech.defaultInterest!.defaultRate, equals(0.065));
      expect(diskartech.defaultInterest!.tierCapAmount, equals(50000));
      expect(diskartech.defaultInterest!.secondaryInterestRate, equals(0.030));
    });

    test('Institution toMap and fromMap serialization', () {
      final institution = Institution(
        id: 'testbank',
        name: 'Test Bank',
        type: InstitutionType.bank,
        iconKey: 'bank',
        currency: 'PHP',
        hasInterest: true,
      );

      final map = institution.toMap();
      expect(map['id'], equals('testbank'));
      expect(map['name'], equals('Test Bank'));
      expect(map['type'], equals('bank'));
      expect(map['has_interest'], equals(1));

      final deserialized = Institution.fromMap(map);
      expect(deserialized.id, equals('testbank'));
      expect(deserialized.name, equals('Test Bank'));
      expect(deserialized.type, equals(InstitutionType.bank));
      expect(deserialized.hasInterest, isTrue);
    });

    test('registerCustom dynamically adds custom user institution', () {
      final customBank = Institution(
        id: 'my_coop_bank',
        name: 'My Local Coop',
        type: InstitutionType.bank,
        iconKey: 'bank',
      );

      InstitutionRegistry.registerCustom(customBank);

      final fetched = InstitutionRegistry.getById('my_coop_bank');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('My Local Coop'));
      expect(
        InstitutionRegistry.banks.any((b) => b.id == 'my_coop_bank'),
        isTrue,
      );

      InstitutionRegistry.clearCustom();
      expect(InstitutionRegistry.getById('my_coop_bank'), isNull);
    });
  });
}
