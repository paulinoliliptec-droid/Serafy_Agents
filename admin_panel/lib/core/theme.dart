import 'package:flutter/material.dart';
import 'constants.dart';

final adminTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.surface,
  cardTheme: CardTheme(
    color: AppColors.cardBg,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1E293B),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: Color(0xFF1E293B),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  dataTableTheme: DataTableThemeData(
    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
    dataRowColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) return const Color(0xFFF8FAFC);
      return Colors.white;
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
);
