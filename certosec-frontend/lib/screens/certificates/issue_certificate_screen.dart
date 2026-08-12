import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/error_banner.dart';
import '../../models/certificate.dart';
import '../../models/student.dart';
import '../../providers/certificates_provider.dart';
import '../../providers/students_provider.dart';

/// IssueCertificateScreen lets an admin mint a new blockchain certificate for
/// an existing student.
///
/// The student is chosen from the loaded directory ([StudentsProvider]); the
/// screen loads the first page on entry if needed. After a successful issue
/// the created certificate is already in [CertificatesProvider], so the app
/// can navigate straight to its details (QR code, blockchain proof).
class IssueCertificateScreen extends StatefulWidget {
  const IssueCertificateScreen({super.key});

  @override
  State<IssueCertificateScreen> createState() =>
      _IssueCertificateScreenState();
}

class _IssueCertificateScreenState extends State<IssueCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _studentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentsProvider = context.read<StudentsProvider>();
      if (studentsProvider.students.isEmpty && !studentsProvider.isLoading) {
        studentsProvider.loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  CertificateDraft _buildDraft() {
    return CertificateDraft(
      studentId: _studentId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<CertificatesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final certificate = await provider.issueCertificate(_buildDraft());

    if (!mounted) return;
    if (certificate != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Certificate ${certificate.uid} issued.')),
      );
      context.go(RouteNames.detail(RouteNames.certificateDetails, certificate.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final certificatesProvider = context.watch<CertificatesProvider>();
    final studentsProvider = context.watch<StudentsProvider>();

    if (studentsProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Issue certificate')),
        body: const AppLoadingView(message: 'Loading students…'),
      );
    }

    if (studentsProvider.students.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Issue certificate')),
        body: AppEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No students yet',
          message:
              'Add a student first so a certificate can be issued against '
              'their profile.',
          actionLabel: 'Add student',
          onAction: () => context.go(RouteNames.studentAdd),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Issue certificate')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.pagePadding,
                children: [
                  Text(
                    'Mint a blockchain-backed certificate for a student. '
                    'A shareable QR code is generated automatically.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (certificatesProvider.errorMessage != null) ...[
                    AppErrorBanner(
                      message: certificatesProvider.errorMessage!,
                      onDismiss: certificatesProvider.clearError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: _studentId,
                    validator: (value) => value == null
                        ? 'Select a student'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: [
                      for (final student in studentsProvider.students)
                        DropdownMenuItem<String>(
                          value: student.id,
                          child: _StudentMenuItem(student: student),
                        ),
                    ],
                    onChanged: (value) => setState(() => _studentId = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.course,
                    decoration: const InputDecoration(
                      labelText: 'Certificate title',
                      hintText: 'Bachelor of Science in Computer Science',
                      prefixIcon: Icon(Icons.military_tech_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details (optional)',
                      hintText: 'Graduated with distinction, Class of 2026…',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    key: const Key('issue-certificate-submit'),
                    onPressed:
                        certificatesProvider.isBusy ? null : _submit,
                    icon: certificatesProvider.isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(
                      certificatesProvider.isBusy
                          ? 'Issuing…'
                          : 'Issue certificate',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentMenuItem extends StatelessWidget {
  const _StudentMenuItem({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            student.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          student.studentId,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
