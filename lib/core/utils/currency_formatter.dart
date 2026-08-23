// lib/utils/currency_formatter.dart

import 'package:intl/intl.dart';

// Formats an amount according to any ISO 4217 currency code.
String formatMoney(double amount, String currency) {
  final format = NumberFormat.simpleCurrency(name: currency);
  return format.format(amount);
}

String currencySymbol(String currency) {
  return NumberFormat.simpleCurrency(name: currency).currencySymbol;
}
