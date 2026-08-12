import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/status_style.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/app_status_badge.dart';
import '../../models/verification_result.dart';
import '../../providers/verification_provider.dart';
import '../../services/pdf/certificate_pdf_service.dart';

/// VerificationResultScreen performs the public verification and renders the
/// verdict.
///
/// The certificate is located either by its `uid` or by its on-chain
/// transaction hash (`txHash`) — exactly one is expected. It always starts a
/// fresh verification ([VerificationProvider] resets prior state), so
/// revisiting the route re-checks the certificate.
class VerificationResultScreen extends StatefulWidget {
  const VerificationResultScreen({
    super.key,
    required this.uid,
    required this.txHash,
  });

  final String uid;
  final String txHash;

  @override
  State<VerificationResultScreen> createState() =>
      _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerificationProvider>().verify(widget.uid, widget.txHash);
    });
  }

  void _retry() {
    context.read<VerificationProvider>().verify(widget.uid, widget.txHash);
  }

  Future<void> _downloadCertificate(VerificationResult result) async {
    final messenger = ScaffoldMessenger.of(context);
    final pdfService = CertificatePdfService();
    await pdfService.shareCertificate(
      CertificatePdfDocument.fromVerificationResult(result),
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Certificate PDF ready for sharing.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VerificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification result'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildBody(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(VerificationProvider provider) {
    if (provider.isLoading) {
      return const AppLoadingView(message: 'Checking the blockchain record…');
    }
    if (provider.hasError) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: _retry,
      );
    }
    final result = provider.result;
    if (result == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        _VerdictCard(result: result),
        if (result.certificateTitle != null ||
            result.studentName != null ||
            result.transactionHash != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CertificateInfoCard(result: result),
        ],
        if (result.isValid) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _downloadCertificate(result),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download certificate'),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Verify another'),
        ),
      ],
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = StatusStyle.verification(result.status);
    final (title, icon, message) = switch (result.status) {
      VerificationStatus.valid => (
        'Certificate verified',
        Icons.verified_rounded,
        'This certificate is authentic.',
      ),
      VerificationStatus.invalid => (
        'Certificate not found',
        Icons.cancel_outlined,
        'No matching certificate was found. Check the UID and try again.',
      ),
      VerificationStatus.tampered => (
        'Certificate tampered',
        Icons.warning_amber_rounded,
        'This certificate has been altered and cannot be trusted.',
      ),
    };

    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              result.uid,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (result.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppStatusBadge(
              label: result.status.label,
              color: color,
              icon: icon,
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateInfoCard extends StatelessWidget {
  const _CertificateInfoCard({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <({IconData icon, String label, String value})>[
      if (result.studentName != null && result.studentName!.isNotEmpty)
        (
          icon: Icons.person_outline_rounded,
          label: 'Issued to',
          value: result.studentName!,
        ),
      if (result.certificateTitle != null &&
          result.certificateTitle!.isNotEmpty)
        (
          icon: Icons.military_tech_outlined,
          label: 'Certificate',
          value: result.certificateTitle!,
        ),
      if (result.issuedAt != null)
        (
          icon: Icons.calendar_today_outlined,
          label: 'Issued on',
          value: FormatUtils.date(result.issuedAt!),
        ),
      if (result.transactionHash != null)
        (
          icon: Icons.link_rounded,
          label: 'Blockchain hash',
          value: FormatUtils.truncateMiddle(
            result.transactionHash!,
            head: 12,
            tail: 8,
          ),
        ),
    ];

    return Card(
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.cardPadding,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Certificate details',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          for (final (index, row) in rows.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: theme.colorScheme.outlineVariant,
              ),
            ListTile(
              leading: Icon(row.icon, color: theme.colorScheme.primary),
              title: Text(row.label, style: theme.textTheme.labelMedium),
              subtitle: Text(
                row.value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
