// lib/utils/category_icons.dart

import 'package:flutter/material.dart';

const Map<String, IconData> categoryIconMap = {
  'restaurant': Icons.restaurant_rounded,
  'car': Icons.directions_car_rounded,
  'receipt': Icons.receipt_long_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'home': Icons.home_rounded,
  'health': Icons.local_hospital_rounded,
  'school': Icons.school_rounded,
  'entertainment': Icons.movie_rounded,
  'phone': Icons.phone_iphone_rounded,
  'gift': Icons.card_giftcard_rounded,
  'salary': Icons.payments_rounded,
  'wallet': Icons.account_balance_wallet_rounded,
  'other': Icons.category_rounded,
};

IconData iconForKey(String key) {
  return categoryIconMap[key] ?? Icons.category_rounded;
}

// Every option shown in the icon picker when adding/editing a category.
List<MapEntry<String, IconData>> get categoryIconOptions =>
    categoryIconMap.entries.toList();

Color colorFromHex(String hex) {
  return Color(int.parse(hex, radix: 16));
}

String colorToHex(Color color) {
  return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
}

const List<Color> categoryColorPalette = [
  Color(0xFFD9A441), // amber
  Color(0xFF1F8A5B), // green
  Color(0xFFD64545), // red
  Color(0xFF3AA76D), // teal-green
  Color(0xFF3A6FD6), // blue
  Color(0xFF8A5CD6), // purple
  Color(0xFFD65C9E), // pink
  Color(0xFF6B7280), // grey
];
