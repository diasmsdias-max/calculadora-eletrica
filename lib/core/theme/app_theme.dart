import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF090C10);
  static const surface = Color(0xFF141A22);
  static const yellow = Color(0xFFFFC107);
  static const red = Color(0xFFE51B23);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: yellow,
      brightness: Brightness.dark,
      surface: surface,
    ).copyWith(
      primary: yellow,
      secondary: red,
      error: red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
