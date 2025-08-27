import 'package:flutter/material.dart';
import 'package:staff_app/theme/colors.dart';


class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightText,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF333333),  // Softer primary black
      secondary: Color(0xFF7E7E7E),
      background: AppColors.lightBackground,
      surface: AppColors.lightCard,
    ),
    cardColor: AppColors.lightCard,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightText),
      bodyMedium: TextStyle(color: AppColors.lightSubText),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFE0E0E0),   // Softer white for primary
      secondary: Color(0xFFB0B0B0),
      background: AppColors.darkBackground,
      surface: AppColors.darkCard,
    ),
    cardColor: AppColors.darkCard,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkText),
      bodyMedium: TextStyle(color: AppColors.darkSubText),
    ),
  );
}