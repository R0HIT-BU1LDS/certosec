import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_status_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

/// ProfileScreen is the signed-in user's identity and account hub.
///
/// It renders the operator's details from [AuthProvider], links to Settings,
/// and hosts the sign-out action (with confirmation).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to manage certificates.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((auth) => auth.user);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: AppSpacing.pagePadding,
              children: [
                _UserHeaderCard(user: user),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.settings_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text('Settings'),
                        subtitle: const Text(
                          'Appearance and account preferences',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go(RouteNames.settings),
                      ),
                      Divider(
                        height: 1,
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.logout_rounded,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          'Sign out',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _confirmSignOut(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserHeaderCard extends StatelessWidget {
  const _UserHeaderCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user?.name ?? 'Operator';
    final email = user?.email ?? '';

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            AppAvatar(name: name, imageUrl: user?.avatarUrl, radius: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppStatusBadge(
              label: user?.role.label ?? 'Admin',
              color: theme.colorScheme.primary,
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${AppConfig.appName} ${AppConfig.appVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
