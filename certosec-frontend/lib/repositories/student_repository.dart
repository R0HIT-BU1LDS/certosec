import '../models/pagination.dart';
import '../models/student.dart';
import '../models/student_draft.dart';
import '../services/api/student_gateway.dart';

/// StudentRepository is the single orchestrator for student business rules.
///
/// It is intentionally thin today (the rules currently live in the gateway
/// contract) but exists so that cross-cutting concerns — caching, audit
/// logging, offline queues — have a stable home that screens never bypass.
class StudentRepository {
  StudentRepository({required StudentGateway gateway}) : _gateway = gateway;

  final StudentGateway _gateway;

  Future<Paginated<Student>> fetchStudents({
    required int page,
    required int pageSize,
    String? search,
    String? department,
  }) {
    return _gateway.fetchStudents(
      page: page,
      pageSize: pageSize,
      search: search,
      department: department,
    );
  }

  Future<Student> fetchStudent(String id) => _gateway.fetchStudent(id);

  Future<Student> createStudent(StudentDraft draft) =>
      _gateway.createStudent(draft);

  Future<Student> updateStudent(String id, StudentDraft draft) =>
      _gateway.updateStudent(id, draft);

  Future<void> deleteStudent(String id) => _gateway.deleteStudent(id);
}
