import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Identidade visual BOECKER
  static const background = Color(0xFF090C10);
  static const surface = Color(0xFF141A22);
  static const surfaceHigh = Color(0xFF1B222C);
  static const yellow = Color(0xFFFFC107);
  static const red = Color(0xFFE51B23);
  static const textPrimary = Color(0xFFF7F7F7);
  static const textSecondary = Color(0xFFC8C8C8);

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: yellow,
      onPrimary: Color(0xFF241C00),
      secondary: red,
      onSecondary: Colors.white,
      error: red,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceHigh,
      outline: Color(0xFF6F7379),
      outlineVariant: Color(0xFF343A42),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceHigh,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: yellow,
        foregroundColor: Color(0xFF241C00),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF241C00)
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? yellow
              : const Color(0xFF343A42),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? yellow
              : const Color(0xFF6F7379),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? yellow : background,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF241C00)
                : textPrimary,
          ),
          side: WidgetStateProperty.all(const BorderSide(color: Color(0xFF6F7379))),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(yellow),
          foregroundColor: WidgetStateProperty.all(const Color(0xFF241C00)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: textSecondary),
        floatingLabelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: yellow, width: 1.4),
        ),
      ),
    );
  }
}
