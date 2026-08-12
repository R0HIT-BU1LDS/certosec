import '../core/utils/model_utils.dart';

/// StudentDraft is the input for creating or updating a student. It is the
/// single payload shape the student form produces, reused by both the create
/// and update endpoints.
class StudentDraft {
  const StudentDraft({
    required this.studentId,
    required this.name,
    required this.email,
    required this.department,
    required this.batch,
    required this.course,
    this.phone,
    this.profilePhotoUrl,
  });

  final String studentId;
  final String name;
  final String email;
  final String department;
  final String batch;
  final String course;
  final String? phone;
  final String? profilePhotoUrl;

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'name': name,
        'email': email,
        'department': department,
        'batch': batch,
        'course': course,
        if (phone != null) 'phone': phone,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      };

  /// Normalizes a draft from model JSON so the edit form can be prefilled
  /// from an existing student.
  static StudentDraft fromStudent(Map<String, dynamic> json) {
    return StudentDraft(
      studentId:
          ModelUtils.pick(json, [
            'studentId',
            'student_id',
            'rollNo',
          ])?.toString() ??
          '',
      name:
          ModelUtils.pick(json, [
            'name',
            'fullName',
            'full_name',
          ])?.toString() ??
          '',
      email: ModelUtils.pick(json, ['email'])?.toString() ?? '',
      department: ModelUtils.pick(json, ['department'])?.toString() ?? '',
      batch: ModelUtils.pick(json, ['batch', 'cohort'])?.toString() ?? '',
      course:
          ModelUtils.pick(json, [
            'course',
            'program',
            'programme',
          ])?.toString() ??
          '',
      phone: ModelUtils.pick(json, [
        'phone',
        'phoneNumber',
        'phone_number',
      ])?.toString(),
      profilePhotoUrl: ModelUtils.pick(json, [
        'profilePhotoUrl',
        'profile_photo_url',
        'photoUrl',
        'avatarUrl',
      ])?.toString(),
    );
  }
}
