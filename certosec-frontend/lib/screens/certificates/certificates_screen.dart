import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/status_style.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/app_pagination_controls.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_status_badge.dart';
import '../../models/certificate.dart';
import '../../providers/certificates_provider.dart';

/// CertificatesScreen is the searchable, filterable, paginated certificate
/// ledger.
///
/// State lives in [CertificatesProvider]; this widget only renders it. Search
/// matches the uid or recipient name, and the status chips filter exactly —
/// both are applied server-side and reset the list to page 1.
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CertificatesProvider>();
      if (provider.certificates.isEmpty && !provider.isLoading) {
        provider.loadInitial();
      }
    });
  }

  void _goToCertificate(String uid) {
    context.go(RouteNames.detail(RouteNames.certificateDetails, uid));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CertificatesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificates'),
        actions: [
          IconButton(
            tooltip: 'Issue certificate',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.go(RouteNames.issueCertificate),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: AppSearchBar(
                onChanged: (query) => provider.setSearch(query),
                hintText: 'Search by UID or student',
              ),
            ),
            _StatusFilter(
              selected: provider.status,
              onSelected: provider.setStatus,
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(child: _buildBody(provider)),
            if (!provider.isLoading && provider.certificates.isNotEmpty)
              AppPaginationControls(
                page: provider.page,
                totalPages: provider.totalPages,
                total: provider.total,
                pageSize: CertificatesProvider.pageSize,
                isLoading: provider.isLoadingMore,
                onPrevious: provider.previousPage,
                onNext: provider.nextPage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CertificatesProvider provider) {
    if (provider.isLoading) {
      return const AppLoadingView(message: 'Loading certificates…');
    }
    if (provider.hasError && provider.certificates.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: provider.reload,
      );
    }
    if (provider.certificates.isEmpty) {
      if (provider.isFiltering) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No certificates match your search',
          message: 'Try a different UID, student name, or status.',
        );
      }
      return AppEmptyState(
        icon: Icons.military_tech_outlined,
        title: 'No certificates yet',
        message:
            'Issue a certificate to a student to add it to the blockchain.',
        actionLabel: 'Issue certificate',
        onAction: () => context.go(RouteNames.issueCertificate),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.reload,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.md,
        ),
        itemCount: provider.certificates.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final certificate = provider.certificates[index];
          return _CertificateTile(
            certificate: certificate,
            onTap: () => _goToCertificate(certificate.uid),
          );
        },
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.selected, required this.onSelected});

  final CertificateStatus? selected;
  final ValueChanged<CertificateStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final statuses = [null, ...CertificateStatus.values];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = selected == status;
          return Center(
            child: ChoiceChip(
              label: Text(status?.label ?? 'All'),
              selected: isSelected,
              onSelected: (_) => onSelected(status),
            ),
          );
        },
      ),
    );
  }
}

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({required this.certificate, required this.onTap});

  final Certificate certificate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.military_tech_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          certificate.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Text(
            '${certificate.uid}  •  ${certificate.studentName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStatusBadge(
              label: certificate.status.label,
              color: StatusStyle.certificate(certificate.status),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
