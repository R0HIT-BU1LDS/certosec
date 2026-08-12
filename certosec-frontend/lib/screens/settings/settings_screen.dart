import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_enums.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/theme_provider.dart';

/// SettingsScreen hosts the operator's in-app preferences.
///
/// Currently that is the appearance preference (system / light / dark),
/// persisted through [ThemeProvider] so the choice survives restarts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: AppSpacing.pagePadding,
              children: [
                Text(
                  'Appearance',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose how CertoSec looks on this device.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return SegmentedButton<ThemePreference>(
                          segments: const [
                            ButtonSegment(
                              value: ThemePreference.system,
                              icon: Icon(Icons.brightness_auto_outlined),
                              label: Text('System'),
                            ),
                            ButtonSegment(
                              value: ThemePreference.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemePreference.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {themeProvider.preference},
                          onSelectionChanged: (selection) {
                            themeProvider.setPreference(selection.first);
                          },
                          showSelectedIcon: false,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('About', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${AppConfig.appName} — ${AppConfig.appTagline}. '
                          'Version ${AppConfig.appVersion}.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
