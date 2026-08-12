import 'package:flutter/widgets.dart';

/// AppSpacing enforces a consistent 4px-based spacing rhythm across the app.
///
/// Widgets must never hard-code pixel values for gaps, padding, or radius;
/// they reference these constants so the whole UI scales consistently and
/// any future redesign touches one file.
abstract final class AppSpacing {
  // Base rhythm.
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Corner radii.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // Control metrics.
  static const double cardRadius = 16;
  static const double controlRadius = 12;
  static const double buttonHeight = 52;
  static const double inputHeight = 56;

  // Shared insets.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);
}
