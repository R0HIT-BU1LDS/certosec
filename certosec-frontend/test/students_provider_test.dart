import 'package:certosec/models/student_draft.dart';
import 'package:certosec/providers/students_provider.dart';
import 'package:certosec/repositories/student_repository.dart';
import 'package:certosec/services/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late StudentsProvider provider;

  StudentsProvider buildProvider(FakeStudentGateway gateway) {
    return StudentsProvider(StudentRepository(gateway: gateway));
  }

  tearDown(() {
    provider.dispose();
  });

  test('loadInitial populates the directory and pagination metadata', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);

    expect(provider.isLoading, isFalse);
    await provider.loadInitial();

    expect(provider.students, hasLength(3));
    expect(provider.total, 3);
    expect(provider.totalPages, 1);
    expect(provider.hasMore, isFalse);
    expect(provider.hasError, isFalse);
  });

  test('setSearch filters server-side and resets to page 1', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    await provider.setSearch('carol');
    expect(provider.search, 'carol');
    expect(provider.students, hasLength(1));
    expect(provider.students.single.name, 'Carol White');

    await provider.setSearch('');
    expect(provider.students, hasLength(3));
  });

  test('setDepartment narrows to the selected department', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    await provider.setDepartment('Physics');
    expect(provider.department, 'Physics');
    expect(provider.students.single.name, 'Carol White');

    await provider.setDepartment(null);
    expect(provider.students, hasLength(3));
  });

  test('addStudent appends and refreshes the current page', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    const draft = StudentDraft(
      studentId: 'PHY-2025-099',
      name: 'Dana Green',
      email: 'dana.green@university.edu',
      department: 'Physics',
      batch: '2025',
      course: 'BSc Physics',
    );

    final added = await provider.addStudent(draft);
    expect(added, isTrue);
    expect(provider.students.any((s) => s.name == 'Dana Green'), isTrue);
    expect(provider.total, 4);
  });

  test('updateStudent reflects changes in the list', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    const draft = StudentDraft(
      studentId: 'CS-2024-001',
      name: 'Alice J. Johnson',
      email: 'alice@university.edu',
      department: 'Computer Science',
      batch: '2024',
      course: 'BSc Computer Science',
    );

    final updated = await provider.updateStudent('student-1', draft);
    expect(updated, isTrue);
    expect(provider.students.any((s) => s.name == 'Alice J. Johnson'), isTrue);
  });

  test('deleteStudent removes the record', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    final deleted = await provider.deleteStudent('student-2');
    expect(deleted, isTrue);
    expect(provider.students.any((s) => s.name == 'Bob Smith'), isFalse);
    expect(provider.total, 2);
  });

  test(
    'mutations surface the server message and return false on failure',
    () async {
      final gateway = FakeStudentGateway(
        seed: defaultStudents(),
        failWith: ApiException.server('Directory temporarily unavailable.'),
      );
      provider = buildProvider(gateway);
      await provider.loadInitial();

      const draft = StudentDraft(
        studentId: 'PHY-2025-099',
        name: 'Dana Green',
        email: 'dana.green@university.edu',
        department: 'Physics',
        batch: '2025',
        course: 'BSc Physics',
      );

      expect(await provider.addStudent(draft), isFalse);
      expect(provider.errorMessage, 'Directory temporarily unavailable.');
      expect(provider.hasError, isTrue);

      provider.clearError();
      expect(provider.hasError, isFalse);
    },
  );

  test('fetchStudent merges a deep-linked record into the cache', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);

    expect(provider.studentById('student-1'), isNull);
    await provider.fetchStudent('student-1');
    expect(provider.studentById('student-1')?.name, 'Alice Johnson');
  });

  test('reload re-fetches the current page', () async {
    final gateway = FakeStudentGateway(seed: defaultStudents());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    await provider.reload();
    expect(provider.students, hasLength(3));
    expect(gateway.fetchCalls, 2);
  });
}
