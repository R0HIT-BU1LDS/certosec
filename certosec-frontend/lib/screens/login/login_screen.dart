import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/logo_widget.dart';
import '../../providers/auth_provider.dart';

/// LoginScreen is the administrator sign-in experience.
///
/// It owns only presentation concerns: the form (validation), the loading and
/// error states surfaced by [AuthProvider], and the forgot-password dialog.
/// Business logic (calling the API, storing tokens, redirecting) lives in the
/// provider and router — this screen never touches storage or HTTP.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignInPressed() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    // On success the router's redirect moves the user to the dashboard
    // automatically (AuthProvider.status flips to authenticated).
  }

  Future<void> _onForgotPasswordPressed() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(emailController: _emailController),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final errorMessage = authProvider.errorMessage;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: _LoginCard(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    isLoading: authProvider.isLoading,
                    errorMessage: errorMessage,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSignIn: _onSignInPressed,
                    onForgotPassword: _onForgotPasswordPressed,
                    onDismissError: authProvider.clearError,
                    horizontal: wide,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onDismissError,
    required this.horizontal,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onDismissError;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: LogoWidget(
                size: horizontal ? 64 : 80,
                horizontal: horizontal,
              ),
            ),
            SizedBox(height: horizontal ? AppSpacing.xl : AppSpacing.lg),
            Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in to the institution admin console.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AppValidators.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'admin@university.edu',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: AppValidators.password,
              onFieldSubmitted: (_) => onSignIn(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onTogglePassword,
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (errorMessage != null) ...[
              AppErrorBanner(message: errorMessage!, onDismiss: onDismissError),
              const SizedBox(height: AppSpacing.md),
            ],
            FilledButton(
              onPressed: isLoading ? null : onSignIn,
              child: _SubmitLabel(isLoading: isLoading),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => context.push(RouteNames.verification),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Verify a certificate'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Protected by CertoSec blockchain verification',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitLabel extends StatelessWidget {
  const _SubmitLabel({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
      );
    }
    return const Text('Sign In');
  }
}

/// Forgot-password dialog. Pre-fills the email from the login form so the
/// user rarely has to type it twice.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.emailController});

  final TextEditingController emailController;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailController.text);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final accepted = await authProvider.forgotPassword(
      _emailController.text.trim(),
    );
    if (!mounted) return;

    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If that email exists, a reset link is on its way.'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<AuthProvider>().forgotPasswordLoading;
    final errorMessage = context.watch<AuthProvider>().errorMessage;

    return AlertDialog(
      title: const Text('Reset your password'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your account email and we will send you a reset link.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                validator: AppValidators.email,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppErrorBanner(
                  message: errorMessage,
                  onDismiss: context.read<AuthProvider>().clearError,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send reset link'),
        ),
      ],
    );
  }
}
