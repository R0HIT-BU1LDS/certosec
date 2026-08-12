import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/logo_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// SplashScreen is the application's boot entry point.
///
/// Responsibilities:
/// 1. Warm up persisted preferences (theme) so no flash occurs later.
/// 2. Run the session check (validate the stored token against the backend).
/// 3. Hold the branded moment for the configured minimum duration, then let
///    the AppRouter redirect decide where the known session goes next.
///
/// The screen never navigates itself: it only produces state, and the router
/// (which listens to AuthProvider) performs the redirect. This keeps
/// navigation decision-making in exactly one place.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    await Future.wait([
      Future<void>.delayed(AppConfig.minimumSplashDuration),
      context.read<ThemeProvider>().load(),
      context.read<AuthProvider>().checkSession(),
    ]);
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoWidget(size: 96),
            const SizedBox(height: AppSpacing.xl),
            if (_ready)
              const _SplashProgressNote()
            else
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown after the session check completes. Keeps the splash frame stable
/// until the router performs the actual redirect (typically within one frame).
class _SplashProgressNote extends StatelessWidget {
  const _SplashProgressNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Verifying session…',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
