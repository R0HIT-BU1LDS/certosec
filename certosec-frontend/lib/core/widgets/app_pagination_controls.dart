import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/format_utils.dart';

/// AppPaginationControls is the compact footer row used by paginated list
/// screens: a "showing X–Y of Z" summary, page indicator, and prev/next
/// buttons.
class AppPaginationControls extends StatelessWidget {
  const AppPaginationControls({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.onPrevious,
    required this.onNext,
    this.isLoading = false,
  });

  final int page;
  final int totalPages;
  final int total;
  final int pageSize;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isLoading;

  int get _start => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get _end {
    if (total == 0) return 0;
    final end = page * pageSize;
    return end > total ? total : end;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('No records', style: muted, textAlign: TextAlign.center),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $_start–$_end of ${FormatUtils.number(total)}',
              style: muted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous page',
            onPressed: page > 1 && !isLoading ? onPrevious : null,
          ),
          Text(
            'Page $page of $totalPages',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next page',
            onPressed: page < totalPages && !isLoading ? onNext : null,
          ),
        ],
      ),
    );
  }
}
