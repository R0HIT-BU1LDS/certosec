import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/departments.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_view.dart';
import '../../core/widgets/error_banner.dart';
import '../../models/student_draft.dart';
import '../../providers/students_provider.dart';

/// AddEditStudentScreen handles both creating and editing a student.
///
/// With [studentId] null it is the "Add student" form; otherwise it prefills
/// from the copy in [StudentsProvider] and becomes the edit form. The same
/// form fields and validation rules drive both modes, and the title/button
/// labels adapt accordingly.
class AddEditStudentScreen extends StatefulWidget {
  const AddEditStudentScreen({super.key, this.studentId});

  final String? studentId;

  bool get isEditing => studentId != null;

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _studentIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _batchController;
  late final TextEditingController _courseController;
  late final TextEditingController _phoneController;
  late final TextEditingController _photoUrlController;
  String? _department;
  bool _prefilled = false;

  String get _title => widget.isEditing ? 'Edit student' : 'Add student';
  String get _submitLabel => widget.isEditing ? 'Save changes' : 'Add student';

  @override
  void initState() {
    super.initState();
    _studentIdController = TextEditingController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _batchController = TextEditingController();
    _courseController = TextEditingController();
    _phoneController = TextEditingController();
    _photoUrlController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isEditing) _prefill();
    });
  }

  void _prefill() {
    final provider = context.read<StudentsProvider>();
    final student = provider.studentById(widget.studentId!);
    if (student == null) return;

    _studentIdController.text = student.studentId;
    _nameController.text = student.name;
    _emailController.text = student.email;
    _batchController.text = student.batch;
    _courseController.text = student.course;
    _phoneController.text = student.phone ?? '';
    _photoUrlController.text = student.profilePhotoUrl ?? '';
    _department = student.department;
    _prefilled = true;
    setState(() {});
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _batchController.dispose();
    _courseController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  StudentDraft _buildDraft() {
    return StudentDraft(
      studentId: _studentIdController.text.trim(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      department: _department ?? '',
      batch: _batchController.text.trim(),
      course: _courseController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      profilePhotoUrl: _photoUrlController.text.trim().isEmpty
          ? null
          : _photoUrlController.text.trim(),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<StudentsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final draft = _buildDraft();

    final success = widget.isEditing
        ? await provider.updateStudent(widget.studentId!, draft)
        : await provider.addStudent(draft);

    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing ? 'Student updated.' : '${draft.name} was added.',
          ),
        ),
      );
      context.go(RouteNames.students);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentsProvider>();

    if (widget.isEditing && !_prefilled && provider.students.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: provider.isLoading
            ? const AppLoadingView(message: 'Loading student…')
            : AppErrorState(
                message: provider.errorMessage ?? 'Student not found.',
                onRetry: () {
                  final id = widget.studentId;
                  if (id != null) provider.fetchStudent(id);
                },
              ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
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
                    widget.isEditing
                        ? 'Update the student’s details. Changes take effect '
                              'immediately.'
                        : 'Record a new student so certificates can be issued '
                              'against their profile.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (provider.errorMessage != null) ...[
                    AppErrorBanner(
                      message: provider.errorMessage!,
                      onDismiss: provider.clearError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextFormField(
                    controller: _studentIdController,
                    textCapitalization: TextCapitalization.characters,
                    validator: AppValidators.studentId,
                    decoration: const InputDecoration(
                      labelText: 'Student ID',
                      hintText: 'CS-2024-001',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.name,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      hintText: 'Jane Doe',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: AppValidators.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'jane.doe@university.edu',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _department,
                    validator: AppValidators.department,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    items: [
                      for (final department in Departments.all)
                        DropdownMenuItem(
                          value: department,
                          child: Text(department),
                        ),
                    ],
                    onChanged: (value) => setState(() => _department = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _batchController,
                          keyboardType: TextInputType.number,
                          validator: AppValidators.batchYear,
                          decoration: const InputDecoration(
                            labelText: 'Batch',
                            hintText: '2024',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _courseController,
                          textCapitalization: TextCapitalization.words,
                          validator: AppValidators.course,
                          decoration: const InputDecoration(
                            labelText: 'Course',
                            hintText: 'BSc Computer Science',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.optionalPhone,
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                      hintText: '+1 555 010 2030',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _photoUrlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Profile photo URL (optional)',
                      hintText: 'https://…',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    key: const Key('student-form-submit'),
                    onPressed: provider.isBusy ? null : _submit,
                    child: provider.isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(_submitLabel),
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
