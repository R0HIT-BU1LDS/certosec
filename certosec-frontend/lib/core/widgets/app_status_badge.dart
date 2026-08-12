import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// AppStatusBadge is a small tonal label used to convey status or metadata
/// (department, batch, verification state) without the weight of a full chip.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final foreground = isDark
        ? Color.lerp(color, Colors.white, 0.35)!
        : Color.lerp(color, Colors.black, 0.15)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
