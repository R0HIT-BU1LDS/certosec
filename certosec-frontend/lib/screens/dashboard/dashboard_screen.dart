import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format_utils.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

/// DashboardScreen is the authenticated home screen.
///
/// It renders the session's aggregate statistics from [DashboardProvider]
/// inside the responsive shell established in Phase 1: a greeting, quick
/// actions, a stat grid, and the analytics/activity panels.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go(RouteNames.profile),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Consumer<DashboardProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.stats == null) {
                      return const AppLoadingView(
                        message: 'Loading statistics…',
                      );
                    }
                    if (provider.stats == null) {
                      return AppErrorState(
                        message:
                            provider.errorMessage ??
                            'Could not load dashboard statistics.',
                        onRetry: () => provider.load(force: true),
                      );
                    }
                    return ListView(
                      padding: AppSpacing.pagePadding,
                      children: [
                        const _WelcomeHeader(),
                        const SizedBox(height: AppSpacing.lg),
                        _QuickActions(
                          onAddStudent: () => context.go(RouteNames.studentAdd),
                          onIssueCertificate: () =>
                              context.go(RouteNames.issueCertificate),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _StatGrid(stats: provider.stats!),
                        const SizedBox(height: AppSpacing.lg),
                        const _AnalyticsPanel(),
                        const SizedBox(height: AppSpacing.lg),
                        const _RecentActivityPanel(),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = context.select<AuthProvider, String>(
      (auth) => auth.user?.firstName ?? 'Admin',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $firstName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Here is what is happening across your institution today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddStudent,
    required this.onIssueCertificate,
  });

  final VoidCallback onAddStudent;
  final VoidCallback onIssueCertificate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.tonalIcon(
          onPressed: onAddStudent,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add Student'),
        ),
        OutlinedButton.icon(
          onPressed: onIssueCertificate,
          icon: const Icon(Icons.military_tech_outlined),
          label: const Text('Issue Certificate'),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        icon: Icons.people_alt_outlined,
        label: 'Total Students',
        value: FormatUtils.count(stats.totalStudents),
      ),
      (
        icon: Icons.military_tech_outlined,
        label: 'Total Certificates',
        value: FormatUtils.count(stats.totalCertificates),
      ),
      (
        icon: Icons.today_outlined,
        label: 'Issued Today',
        value: FormatUtils.count(stats.issuedToday),
      ),
      (
        icon: Icons.verified_outlined,
        label: 'Verified',
        value: FormatUtils.count(stats.verifiedCertificates),
      ),
      (
        icon: Icons.pending_actions_outlined,
        label: 'Pending',
        value: FormatUtils.count(stats.pendingCertificates),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: columns == 3 ? 1.55 : 2.0,
          children: [
            for (final card in cards)
              _StatCard(icon: card.icon, label: card.label, value: card.value),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 26),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insert_chart_outlined_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Issuance analytics', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Charts appear once the analytics endpoint is available. '
              'This panel will visualise monthly issuance and verification '
              'trends.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent activity', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 44,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Nothing yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Activity will appear here once certificates are issued.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
