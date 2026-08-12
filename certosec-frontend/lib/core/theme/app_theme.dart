import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// AppTheme builds the two ThemeData instances the app exposes (light and
/// dark). It is the single place where Material 3 component styles are tuned
/// to the house style: rounded corners, soft shadows, generous control sizes,
/// and a restrained professional palette.
abstract final class AppTheme {
  static ThemeData light() => _build(
    isDark: false,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.surfaceVariant,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.primaryDark,
      onTertiary: AppColors.onPrimary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceVariant,
      surfaceContainerHighest: AppColors.surfaceVariant,
    ),
  );

  static ThemeData dark() => _build(
    isDark: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryContainer,
      primaryContainer: Color(0xFF22406B),
      onPrimaryContainer: AppColors.darkTextPrimary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimaryContainer,
      secondaryContainer: AppColors.darkSurfaceVariant,
      onSecondaryContainer: AppColors.darkTextPrimary,
      tertiary: AppColors.primaryLight,
      onTertiary: AppColors.onPrimaryContainer,
      error: Color(0xFFEF9A9A),
      onError: Color(0xFF2D0A0A),
      errorContainer: Color(0xFF5C2323),
      onErrorContainer: Color(0xFFF4C7C7),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkBackground,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceVariant,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
    ),
  );

  static ThemeData _build({
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final textTheme = AppTypography.textTheme(colorScheme);
    final isLight = !isDark;
    final shadowColor = isLight ? const Color(0x1A1F2937) : Colors.black;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleSpacing: AppSpacing.md,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),

      cardTheme: CardThemeData(
        elevation: isLight ? 1 : 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: isDark
              ? BorderSide(color: colorScheme.outlineVariant)
              : BorderSide.none,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.surfaceVariant
            : AppColors.darkSurfaceVariant,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppColors.textPrimary
            : AppColors.darkSurfaceVariant,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.white : AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        space: 1,
        thickness: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
        selectionHandleColor: colorScheme.primary,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceVariant
            : AppColors.darkSurfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? AppColors.textPrimary : AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
