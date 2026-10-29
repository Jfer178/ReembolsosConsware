import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1463F3);
  static const background = Color(0xFFF2F6FC);
  static const frame = Color(0xFFDCE6F5);
  static const text = Color(0xFF14213D);
  static const muted = Color(0xFF6B7A90);
  static const border = Color(0xFFE3E9F3);

  static const pending = Color(0xFFD97F00);
  static const pendingBg = Color(0xFFFFF3DD);
  static const approved = Color(0xFF16A34A);
  static const approvedBg = Color(0xFFE6F6EC);
  static const rejected = Color(0xFFE11D48);
  static const rejectedBg = Color(0xFFFDE7EC);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF2F80FF), Color(0xFF0A55D8)],
  );
}

ThemeData buildAppTheme() {
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.border),
  );

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.muted),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
