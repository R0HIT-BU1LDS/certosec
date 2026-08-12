import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/status_style.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/app_status_badge.dart';
import '../../models/certificate.dart';
import '../../providers/certificates_provider.dart';
import '../../providers/students_provider.dart';
import '../../services/pdf/certificate_pdf_service.dart';

/// CertificateDetailsScreen shows the full record for one certificate: its
/// shareable QR code, the verified issuer details, and the on-chain proof.
///
/// It prefers the copy already loaded in [CertificatesProvider]; if the
/// certificate is not present (e.g. reached via a deep link or just issued) it
/// falls back to the single-certificate endpoint through the provider.
class CertificateDetailsScreen extends StatefulWidget {
  const CertificateDetailsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<CertificateDetailsScreen> createState() =>
      _CertificateDetailsScreenState();
}

class _CertificateDetailsScreenState extends State<CertificateDetailsScreen> {
  bool _didTryFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CertificatesProvider>();
      if (provider.certificateByUid(widget.uid) == null) {
        provider.fetchCertificate(widget.uid);
        _didTryFetch = true;
      }
    });
  }

  Future<void> _copyVerificationUrl(Certificate certificate) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: certificate.verificationUrl));
    messenger.showSnackBar(
      const SnackBar(content: Text('Verification link copied.')),
    );
  }

  Future<void> _sharePdf(Certificate certificate) async {
    final student = context.read<StudentsProvider>().studentById(
          certificate.studentId,
        );
    final document = CertificatePdfDocument.fromCertificate(
      certificate,
      student: student,
    );
    await CertificatePdfService().shareCertificate(document);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CertificatesProvider>();
    final certificate = provider.certificateByUid(widget.uid);

    if (certificate != null) {
      return _buildDetail(certificate);
    }
    if (provider.isLoading) {
      return const Scaffold(
        body: AppLoadingView(message: 'Loading certificate…'),
      );
    }
    if (provider.hasError && _didTryFetch) {
      return Scaffold(
        appBar: AppBar(title: const Text('Certificate details')),
        body: AppErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.fetchCertificate(widget.uid),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Certificate details')),
      body: AppEmptyState(
        icon: Icons.military_tech_outlined,
        title: 'Certificate not found',
        message: 'This certificate may have been removed.',
      ),
    );
  }

  Widget _buildDetail(Certificate certificate) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate details'),
        actions: [
          IconButton(
            tooltip: 'Share as PDF',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _sharePdf(certificate),
          ),
          IconButton(
            tooltip: 'Copy verification link',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copyVerificationUrl(certificate),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: AppSpacing.pagePadding,
                  children: [
                    _HeaderCard(certificate: certificate),
                    const SizedBox(height: AppSpacing.md),
                    _QrCodeCard(certificate: certificate),
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(certificate: certificate),
                    if (certificate.transactionHash != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _BlockchainCard(certificate: certificate),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () => _sharePdf(certificate),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share as PDF'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => _copyVerificationUrl(certificate),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Copy verification link'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Icon(
              Icons.military_tech_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              certificate.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              certificate.uid,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: [
                AppStatusBadge(
                  label: certificate.status.label,
                  color: StatusStyle.certificate(certificate.status),
                ),
                if (certificate.issuedAt != null)
                  AppStatusBadge(
                    label: FormatUtils.date(certificate.issuedAt!),
                    color: theme.colorScheme.tertiary,
                    icon: Icons.calendar_today_outlined,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCodeCard extends StatelessWidget {
  const _QrCodeCard({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Text('Shareable QR code', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Scanned at any CertoSec verification point.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: QrImageView(
                data: certificate.verificationUrl,
                version: QrVersions.auto,
                size: 208,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <({IconData icon, String label, String value})>[
      (
        icon: Icons.person_outline_rounded,
        label: 'Student',
        value: certificate.studentName,
      ),
      if (certificate.issuedAt != null)
        (
          icon: Icons.calendar_today_outlined,
          label: 'Issued on',
          value: FormatUtils.dateTime(certificate.issuedAt!),
        ),
      (
        icon: Icons.account_balance_outlined,
        label: 'Issuer',
        value: certificate.issuerName ?? AppConfig.orgName,
      ),
      if (certificate.description != null &&
          certificate.description!.isNotEmpty)
        (
          icon: Icons.notes_rounded,
          label: 'Details',
          value: certificate.description!,
        ),
    ];

    return Card(
      child: Column(
        children: [
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
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockchainCard extends StatelessWidget {
  const _BlockchainCard({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <({IconData icon, String label, String value})>[
      if (certificate.transactionHash != null)
        (
          icon: Icons.link_rounded,
          label: 'Transaction hash',
          value: FormatUtils.truncateMiddle(
            certificate.transactionHash!,
            head: 12,
            tail: 8,
          ),
        ),
      if (certificate.chain != null)
        (icon: Icons.hexagon_outlined, label: 'Network', value: certificate.chain!),
      if (certificate.blockNumber != null)
        (
          icon: Icons.tag_rounded,
          label: 'Block',
          value: FormatUtils.number(certificate.blockNumber!),
        ),
    ];

    return Card(
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Blockchain proof',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                AppStatusBadge(
                  label: 'On-chain',
                  color: AppColors.success,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
          for (final (_, row) in rows.indexed) ...[
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
