import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// AppErrorBanner is the compact inline error bar shown inside forms and
/// detail screens when an operation fails (as opposed to [AppErrorState],
/// which is the full-area variant).
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: isDark ? scheme.onErrorContainer : null,
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
