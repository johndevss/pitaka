import 'package:flutter_test/flutter_test.dart';
import 'package:pitaka/utils/currency_formatter.dart';

void main() {
  test('formatMoney formats PHP and USD correctly', () {
    expect(formatMoney(1250.5, 'PHP'), equals('₱1,250.50'));
    expect(formatMoney(50.0, 'USD'), equals('\$50.00'));
  });

  test('currencySymbol returns correct symbol for currency code', () {
    expect(currencySymbol('PHP'), equals('₱'));
    expect(currencySymbol('USD'), equals('\$'));
  });
}