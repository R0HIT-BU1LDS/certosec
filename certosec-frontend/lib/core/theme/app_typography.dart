import 'package:flutter/material.dart';

/// AppTypography centralizes the typography scale.
///
/// It starts from the platform's default Material 3 text theme (which is
/// already accessibility-aware and renders with the platform font stack) and
/// applies the house style: heavier weights for headings, relaxed line height
/// for body copy, and a clearly emphasized label style for buttons.
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme).textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}
