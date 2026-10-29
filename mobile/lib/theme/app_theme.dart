import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF1A2B6D); // color del logo Consware
  static const primary = Color(0xFF1668F2);
  static const background = Color(0xFFF3F7FD);
  static const frame = Color(0xFFDDE8F7);
  static const text = Color(0xFF1B2547);
  static const muted = Color(0xFF6E7A94);
  static const border = Color(0xFFE2E9F4);
  static const tile = Color(0xFFEEF3FB);
  static const purple = Color(0xFF7B5CF0);
  static const purpleBg = Color(0xFFF0ECFE);

  static const pending = Color(0xFFE67E00);
  static const pendingBg = Color(0xFFFFF2DF);
  static const approved = Color(0xFF1E9E55);
  static const approvedBg = Color(0xFFE4F6EA);
  static const rejected = Color(0xFFE2324F);
  static const rejectedBg = Color(0xFFFDE8EC);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B8BFF), Color(0xFF0B5BE0)],
  );
}

class AppShadows {
  static final card = [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static final button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppText {
  static const pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.navy,
  );

  static const subtitle = TextStyle(fontSize: 14, color: AppColors.muted, height: 1.45);
}

/// Superficie blanca con esquinas redondeadas y sombra suave, base de todas las tarjetas.
BoxDecoration cardDecoration({double radius = 20}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: AppShadows.card,
    );

ThemeData buildAppTheme() {
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.border),
  );

  return ThemeData(
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text),
      bodyLarge: TextStyle(color: AppColors.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      disabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.rejected),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.rejected, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
    ),
  );
}
