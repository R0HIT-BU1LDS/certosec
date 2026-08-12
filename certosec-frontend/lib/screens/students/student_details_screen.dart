import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format_utils.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/app_status_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../models/student.dart';
import '../../providers/students_provider.dart';

/// StudentDetailsScreen shows the full record for a single student.
///
/// It prefers the copy already loaded in [StudentsProvider]; if the student is
/// not present (e.g. reached via a deep link) it falls back to the
/// single-student endpoint through the provider.
class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  bool _didTryFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentsProvider>();
      if (provider.studentById(widget.studentId) == null) {
        provider.fetchStudent(widget.studentId);
        _didTryFetch = true;
      }
    });
  }

  Future<void> _confirmDelete(Student student) async {
    final provider = context.read<StudentsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${student.name}?',
      message:
          'This removes the student record and cannot be undone. '
          'Issued certificates are not deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final deleted = await provider.deleteStudent(student.id);
    if (!mounted) return;
    if (deleted) {
      messenger.showSnackBar(
        SnackBar(content: Text('${student.name} was deleted.')),
      );
      context.go(RouteNames.students);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentsProvider>();
    final student = provider.studentById(widget.studentId);

    if (student != null) {
      return _buildDetail(student, provider);
    }
    if (provider.isLoading) {
      return const Scaffold(body: AppLoadingView(message: 'Loading student…'));
    }
    if (provider.hasError && _didTryFetch) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student details')),
        body: AppErrorState(
          message: provider.errorMessage!,
          onRetry: () => provider.fetchStudent(widget.studentId),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Student details')),
      body: AppEmptyState(
        icon: Icons.person_off_outlined,
        title: 'Student not found',
        message: 'This student may have been removed.',
      ),
    );
  }

  Widget _buildDetail(Student student, StudentsProvider provider) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student details'),
        actions: [
          IconButton(
            tooltip: 'Edit student',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go(
              RouteNames.detail(RouteNames.studentEdit, student.id),
            ),
          ),
          IconButton(
            tooltip: 'Delete student',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: provider.isBusy ? null : () => _confirmDelete(student),
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
                    _HeaderCard(student: student),
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(student: student),
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
  const _HeaderCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            AppAvatar(
              name: student.name,
              imageUrl: student.profilePhotoUrl,
              radius: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              student.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              student.studentId,
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
                  label: student.department,
                  color: theme.colorScheme.primary,
                ),
                AppStatusBadge(
                  label: 'Batch ${student.batch}',
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <({IconData icon, String label, String value})>[
      (icon: Icons.mail_outline_rounded, label: 'Email', value: student.email),
      (
        icon: Icons.school_outlined,
        label: 'Department',
        value: student.department,
      ),
      (
        icon: Icons.calendar_today_outlined,
        label: 'Batch',
        value: student.batch,
      ),
      (icon: Icons.menu_book_outlined, label: 'Course', value: student.course),
      if (student.phone != null && student.phone!.isNotEmpty)
        (icon: Icons.phone_outlined, label: 'Phone', value: student.phone!),
      if (student.createdAt != null)
        (
          icon: Icons.history_rounded,
          label: 'Added on',
          value: FormatUtils.date(student.createdAt!),
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
