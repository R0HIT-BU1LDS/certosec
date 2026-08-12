import '../../models/pagination.dart';
import '../../models/student.dart';
import '../../models/student_draft.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'student_gateway.dart';

/// StudentApi is the HTTP implementation of [StudentGateway].
///
///   GET    /students?page=&pageSize=&search=&department=
///   GET    /students/:id
///   POST   /students
///   PUT    /students/:id
///   DELETE /students/:id
class StudentApi implements StudentGateway {
  StudentApi(this._client);

  final ApiClient _client;

  @override
  Future<Paginated<Student>> fetchStudents({
    required int page,
    required int pageSize,
    String? search,
    String? department,
  }) async {
    final response = await _client.get(
      ApiEndpoints.students,
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (department != null && department.isNotEmpty)
          'department': department,
      },
    );
    return Paginated.fromJson(
      response.data! as Map<String, dynamic>,
      Student.fromJson,
    );
  }

  @override
  Future<Student> fetchStudent(String id) async {
    final response = await _client.get(ApiEndpoints.student(id));
    return Student.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<Student> createStudent(StudentDraft draft) async {
    final response = await _client.post(
      ApiEndpoints.students,
      body: draft.toJson(),
    );
    return Student.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<Student> updateStudent(String id, StudentDraft draft) async {
    final response = await _client.put(
      ApiEndpoints.student(id),
      body: draft.toJson(),
    );
    return Student.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _client.delete(ApiEndpoints.student(id));
  }
}
