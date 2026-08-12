import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';

/// VerificationScreen is the public certificate verification experience,
/// reachable without signing in.
///
/// It supports three input modes, switchable with a segmented control:
/// - **Enter UID**: manual entry with live CERT-YYYY-NNNNNN formatting.
/// - **Enter Transaction Hash**: on-chain hash of the issuance transaction.
/// - **Scan QR**: live camera scan of a certificate's QR code. The scanner is
///   built lazily so the manual paths (and widget tests) never touch the
///   camera.
///
/// The screen never talks to the backend itself; it hands the input to the
/// result route, whose screen performs the actual verification.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

enum _VerifyMode { manual, hash, scan }

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uidController = TextEditingController();
  final _txHashController = TextEditingController();
  _VerifyMode _mode = _VerifyMode.manual;
  bool _isNavigating = false;

  @override
  void dispose() {
    _uidController.dispose();
    _txHashController.dispose();
    super.dispose();
  }

  Future<void> _pushResult(String route) {
    if (_isNavigating) return Future.value();
    _isNavigating = true;
    return context.push(route).whenComplete(() {
      _isNavigating = false;
    });
  }

  void _onManualSubmit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _pushResult(
      RouteNames.verificationResultWith(_uidController.text.trim().toUpperCase()),
    );
  }

  void _onHashSubmit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _pushResult(
      RouteNames.verificationResultWithHash(_txHashController.text.trim()),
    );
  }

  void _handleDetected(String payload) {
    if (_isNavigating || payload.trim().isEmpty) return;

    // QR payloads are `$verificationBaseUrl?uid=CERT-...`; extract the uid.
    String? uid = payload.trim().toUpperCase();
    final uri = Uri.tryParse(payload.trim());
    if (uri != null && uri.queryParameters.containsKey('uid')) {
      uid = uri.queryParameters['uid']!.trim().toUpperCase();
    }
    if (!RegExp(r'^CERT-\d{4}-\d{6}$').hasMatch(uid)) return;

    _pushResult(RouteNames.verificationResultWith(uid));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify a certificate'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: AppSpacing.pagePadding,
              children: [
                Text(
                  'Confirm a certificate is authentic by checking it against '
                  'the blockchain record.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<_VerifyMode>(
                  segments: const [
                    ButtonSegment(
                      value: _VerifyMode.manual,
                      icon: Icon(Icons.keyboard_outlined),
                      label: Text('Enter UID'),
                    ),
                    ButtonSegment(
                      value: _VerifyMode.hash,
                      icon: Icon(Icons.hexagon_outlined),
                      label: Text('Transaction Hash'),
                    ),
                    ButtonSegment(
                      value: _VerifyMode.scan,
                      icon: Icon(Icons.qr_code_scanner_rounded),
                      label: Text('Scan QR'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                switch (_mode) {
                  _VerifyMode.manual => _buildManualEntry(theme),
                  _VerifyMode.hash => _buildHashEntry(theme),
                  _VerifyMode.scan => _buildScanner(theme),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntry(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _uidController,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
            inputFormatters: [
              AppValidators.uidInputFormatter,
            ],
            validator: (value) =>
                AppValidators.certificateUid(AppValidators.formatCertificateUidInput(value ?? '')),
            onChanged: (value) {
              final formatted = AppValidators.formatCertificateUidInput(value);
              if (formatted != value) {
                _uidController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(
                    offset: formatted.length,
                  ),
                );
              }
            },
            onFieldSubmitted: (_) => _onManualSubmit(),
            decoration: const InputDecoration(
              labelText: 'Certificate UID',
              hintText: 'CERT-2026-000001',
              prefixIcon: Icon(Icons.military_tech_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('verify-submit'),
            onPressed: _onManualSubmit,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildHashEntry(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _txHashController,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.text,
            validator: (value) =>
                AppValidators.ethereumTransactionHash(value ?? ''),
            onFieldSubmitted: (_) => _onHashSubmit(),
            decoration: const InputDecoration(
              labelText: 'Transaction hash',
              hintText: '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1f3b6776c3d0b7f2c2c39d4a11',
              prefixIcon: Icon(Icons.hexagon_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('verify-hash-submit'),
            onPressed: _onHashSubmit,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AspectRatio(
            aspectRatio: 1,
            child: MobileScanner(
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue;
                  if (raw != null) _handleDetected(raw);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Point the camera at the certificate\'s QR code.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
