import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// LogoWidget renders the CertoSec brand mark: a rounded, gradient square
/// bearing a shield-verified glyph, with the product name beside or below it.
///
/// It is used by the splash and login screens so the brand is rendered from a
/// single source of truth (no duplicated styling).
class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.size = 72,
    this.showName = true,
    this.horizontal = false,
  });

  /// Edge length of the square brand mark.
  final double size;

  /// Whether to render the "CertoSec" wordmark.
  final bool showName;

  /// When true, the wordmark sits beside the mark (row); otherwise below.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(
        Icons.verified_user_rounded,
        color: Colors.white,
        size: size * 0.56,
      ),
    );

    if (!showName) return mark;

    final wordmark = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          AppConfig.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppConfig.appTagline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );

    if (horizontal) {
      return Row(
        children: [
          mark,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: wordmark),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: AppSpacing.md),
        wordmark,
      ],
    );
  }
}
