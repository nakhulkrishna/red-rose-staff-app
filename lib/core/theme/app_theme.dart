import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    const bg = Color(0xFFF3F4F6);
    const card = Colors.white;
    const border = Color(0xFFE5E7EB);
    const textStrong = Color(0xFF111827);
    const textMuted = Color(0xFF6B7280);
    const accent = Color(0xFF1F2937);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: bg,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textStrong,
          fontSize: 34 / 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: textStrong,
          fontWeight: FontWeight.w700,
          fontSize: 32 / 1.45,
        ),
        titleLarge: TextStyle(
          color: textStrong,
          fontWeight: FontWeight.w700,
          fontSize: 24 / 1.25,
        ),
        titleMedium: TextStyle(
          color: textStrong,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: false,
        iconColor: Color(0xFF6B7280),
        textColor: textStrong,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF9FAFB),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        labelStyle: const TextStyle(
          color: textStrong,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  const AppTheme._();
}
