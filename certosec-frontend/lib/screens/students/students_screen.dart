import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/departments.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/app_pagination_controls.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_status_badge.dart';
import '../../core/widgets/app_avatar.dart';
import '../../models/student.dart';
import '../../providers/students_provider.dart';

/// StudentsScreen is the searchable, filterable, paginated student directory.
///
/// State lives in [StudentsProvider]; this widget only renders it. Search and
/// department filter are applied server-side and reset the list to page 1.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentsProvider>();
      if (provider.students.isEmpty && !provider.isLoading) {
        provider.loadInitial();
      }
    });
  }

  void _goToStudent(String id) {
    context.go(RouteNames.detail(RouteNames.studentDetails, id));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            tooltip: 'Add student',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => context.go(RouteNames.studentAdd),
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
                hintText: 'Search by name or student ID',
              ),
            ),
            _DepartmentFilter(
              selected: provider.department,
              onSelected: provider.setDepartment,
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(child: _buildBody(provider)),
            if (!provider.isLoading && provider.students.isNotEmpty)
              AppPaginationControls(
                page: provider.page,
                totalPages: provider.totalPages,
                total: provider.total,
                pageSize: StudentsProvider.pageSize,
                isLoading: provider.isLoadingMore,
                onPrevious: provider.previousPage,
                onNext: provider.nextPage,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(StudentsProvider provider) {
    if (provider.isLoading) {
      return const AppLoadingView(message: 'Loading students…');
    }
    if (provider.hasError && provider.students.isEmpty) {
      return AppErrorState(
        message: provider.errorMessage!,
        onRetry: provider.reload,
      );
    }
    if (provider.students.isEmpty) {
      if (provider.isFiltering) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No students match your search',
          message: 'Try a different name, ID, or department.',
        );
      }
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No students yet',
        message: 'Add your first student to start issuing certificates.',
        actionLabel: 'Add student',
        onAction: () => context.go(RouteNames.studentAdd),
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
        itemCount: provider.students.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final student = provider.students[index];
          return _StudentTile(
            student: student,
            onTap: () => _goToStudent(student.id),
          );
        },
      ),
    );
  }
}

class _DepartmentFilter extends StatelessWidget {
  const _DepartmentFilter({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final departments = [null, ...Departments.all];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: departments.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final department = departments[index];
          final isAll = department == null;
          final isSelected = selected == department;
          return Center(
            child: ChoiceChip(
              label: Text(isAll ? 'All' : department),
              selected: isSelected,
              onSelected: (_) => onSelected(department),
            ),
          );
        },
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: AppAvatar(
          name: student.name,
          imageUrl: student.profilePhotoUrl,
          radius: 24,
        ),
        title: Text(
          student.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Text(
            student.studentId,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStatusBadge(
              label: student.department,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
