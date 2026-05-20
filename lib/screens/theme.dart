import 'package:flutter/material.dart';

class AppTheme {
  // ==================== Main Colors ====================
  static const Color primary = Color(0xFF1E40AF);     // Deep Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF2563EB);

  static const Color background = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;        // Changed to white
  static const Color surfaceColor = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ==================== Main Theme ====================
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: background,
    fontFamily: 'Poppins',                    // Add Poppins later if you want

    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: accent,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      backgroundColor: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ),
  );
}