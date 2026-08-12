import '../core/utils/model_utils.dart';

/// Student is the institution's student record as served by the backend.
///
/// The model is logic-free; [ModelUtils.pick] tolerates both camelCase and
/// snake_case response shapes so a backend rename doesn't break the app.
class Student {
  const Student({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.department,
    required this.batch,
    required this.course,
    this.phone,
    this.profilePhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String studentId;
  final String name;
  final String email;
  final String department;
  final String batch;
  final String course;
  final String? phone;
  final String? profilePhotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: ModelUtils.pick(json, ['id'])?.toString() ?? '',
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
      createdAt: ModelUtils.pickDate(json, ['createdAt', 'created_at']),
      updatedAt: ModelUtils.pickDate(json, ['updatedAt', 'updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'name': name,
    'email': email,
    'department': department,
    'batch': batch,
    'course': course,
    'phone': phone,
    'profilePhotoUrl': profilePhotoUrl,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  /// First name for friendly greetings ("Good morning, Jane").
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
  }
}
