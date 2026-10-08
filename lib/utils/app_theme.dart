

import 'package:flutter/material.dart';

class AppTheme {

  static const Color primary       = Color(0xFF2E7D32);
  static const Color primaryLight  = Color(0xFF60AD5E);
  static const Color primaryDark   = Color(0xFF005005);
  static const Color accent        = Color(0xFFFFC107);
  static const Color background    = Color(0xFFF5F9F5);
  static const Color surface       = Colors.white;
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);


  static const Color healthy  = Color(0xFF4CAF50);
  static const Color low      = Color(0xFFFFC107);
  static const Color moderate = Color(0xFFFF9800);
  static const Color high     = Color(0xFFF44336);


  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: surface,
    ),
  );


  static Color severityColor(String severity) {
    switch (severity) {
      case 'Yellow Alert': return low;
      case 'Orange Alert': return moderate;
      case 'Red Alert':    return high;
      default:             return healthy;
    }
  }

  static IconData severityIcon(String severity) {
    switch (severity) {
      case 'Yellow Alert': return Icons.warning_amber_rounded;
      case 'Orange Alert': return Icons.warning_rounded;
      case 'Red Alert':    return Icons.dangerous_rounded;
      default:             return Icons.check_circle_rounded;
    }
  }
}