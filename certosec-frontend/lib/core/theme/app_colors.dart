import 'package:flutter/material.dart';

/// AppColors is the design system's single color source.
///
/// The palette is intentionally restrained: a professional blue for brand and
/// actions, neutral grays for structure, and a small set of semantic status
/// colors (success / warning / error). No flashy accents.
///
/// Each color is defined once with an explicit light value; dark mode is
/// handled by the dark group below and selected in AppTheme.
abstract final class AppColors {
  // Brand — professional blue.
  static const Color primary = Color(0xFF1E5AA8);
  static const Color primaryDark = Color(0xFF163F7A);
  static const Color primaryLight = Color(0xFF4A82C6);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFD9E6F7);
  static const Color onPrimaryContainer = Color(0xFF0B2B52);

  // Neutrals — light mode.
  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // Neutrals — dark mode.
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF161D26);
  static const Color darkSurfaceVariant = Color(0xFF1E2732);
  static const Color darkTextPrimary = Color(0xFFE7EBEF);
  static const Color darkTextSecondary = Color(0xFF9AA5B1);
  static const Color darkBorder = Color(0xFF2A3441);

  // Semantic status colors.
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE3F2E6);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFDF3E3);
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFBE9E9);
}
