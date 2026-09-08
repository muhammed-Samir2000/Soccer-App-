import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seedColor = Color(0xFF0B6E4F);
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F7F3),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textTheme: Typography.material2021().black.apply(
        displayColor: const Color(0xFF16342A),
        bodyColor: const Color(0xFF3E514B),
      ),
    );
  }
}
