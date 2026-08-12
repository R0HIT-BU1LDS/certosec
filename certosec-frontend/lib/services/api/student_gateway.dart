import '../../models/pagination.dart';
import '../../models/student.dart';
import '../../models/student_draft.dart';

/// StudentGateway is the contract for the student records backend.
///
/// Screens depend on this interface, never on the HTTP implementation
/// directly, so tests can substitute an in-memory fake.
abstract interface class StudentGateway {
  /// Fetches one page of students. [search] matches against name or roll
  /// number; [department] is an exact match. Either may be null.
  Future<Paginated<Student>> fetchStudents({
    required int page,
    required int pageSize,
    String? search,
    String? department,
  });

  Future<Student> fetchStudent(String id);

  Future<Student> createStudent(StudentDraft draft);

  Future<Student> updateStudent(String id, StudentDraft draft);

  Future<void> deleteStudent(String id);
}
