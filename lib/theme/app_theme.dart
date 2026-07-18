// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Prevents instantiation

  // Define Hex Colors
  static const Color primaryMalachite = Color(0xff1f8a5b);
  static const Color primaryHover = Color(0xff166a45);
  static const Color secondaryGold = Color(0xffd9a441);
  static const Color backgroundGreenish = Color(0xfff5f7f5);
  static const Color surfaceWhite = Color(0xffffffff);
  
  static const Color successGreen = Color(0xff2e9f5d);
  static const Color warningOrange = Color(0xffe8a317);
  static const Color errorRed = Color(0xffd64545);

  static const Color textPrimary = Color(0xff222222);
  static const Color textSecondary = Color(0xff666666);
  static const Color textDisabled = Color(0xffa0a0a0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundGreenish,
      
      // Color Scheme Mapping
      colorScheme: const ColorScheme.light(
        primary: primaryMalachite,
        onPrimary: surfaceWhite,
        secondary: secondaryGold,
        onSecondary: textPrimary,
        surface: surfaceWhite,
        onSurface: textPrimary,
        error: errorRed,
        onError: surfaceWhite,
      ),

      // Customizing component styles to match specs
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 20px Card Radius
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMalachite,
          foregroundColor: surfaceWhite,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // 16px Button Radius
          ),
          elevation: 0,
        ).copyWith(
          // Simulating the hover color state change
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
              return primaryHover;
            }
            return null;
          }),
        ),
      ),

      // Base typography adjustment (Using system fallbacks if custom fonts aren't loaded yet)
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
    );
  }
}