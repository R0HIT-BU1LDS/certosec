import 'package:certosec/core/constants/app_enums.dart';
import 'package:certosec/models/auth_session.dart';
import 'package:certosec/models/certificate.dart';
import 'package:certosec/models/dashboard_stats.dart';
import 'package:certosec/models/pagination.dart';
import 'package:certosec/models/student.dart';
import 'package:certosec/models/student_draft.dart';
import 'package:certosec/models/user.dart';
import 'package:certosec/models/verification_result.dart';
import 'package:certosec/services/api/api_exception.dart';
import 'package:certosec/services/api/auth_gateway.dart';
import 'package:certosec/services/api/certificate_gateway.dart';
import 'package:certosec/services/api/dashboard_gateway.dart';
import 'package:certosec/services/api/student_gateway.dart';
import 'package:certosec/services/api/verification_gateway.dart';
import 'package:certosec/services/storage/session_storage.dart';

/// In-memory implementation of [SessionStorage] so boot/login sequences run
/// without a platform channel.
class InMemorySessionStorage implements SessionStorage {
  InMemorySessionStorage([Map<String, String>? initial])
    : _values = {...?initial};

  final Map<String, String> _values;

  @override
  Future<String?> readToken() async => _values['token'];

  @override
  Future<void> writeToken(String token) async => _values['token'] = token;

  @override
  Future<String?> readRefreshToken() async => _values['refresh'];

  @override
  Future<void> writeRefreshToken(String token) async =>
      _values['refresh'] = token;

  @override
  Future<void> clearSession() async {
    _values.remove('token');
    _values.remove('refresh');
  }
}

/// In-memory implementation of the auth backend. Accepts exactly one known
/// credential pair and returns a fixed admin profile; anything else produces
/// an unauthorized error, which mirrors a real backend.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.acceptedPassword = 'password123'});

  static const User adminUser = User(
    id: 'user-1',
    name: 'Jane Admin',
    email: 'admin@university.edu',
    role: UserRole.admin,
  );

  final String acceptedPassword;
  int loginCalls = 0;
  int currentUserCalls = 0;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    if (email == adminUser.email && password == acceptedPassword) {
      return const AuthSession(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        user: adminUser,
      );
    }
    throw ApiException.unauthorized('Invalid email or password.');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<User> fetchCurrentUser() async {
    currentUserCalls++;
    return adminUser;
  }
}

/// In-memory implementation of the dashboard backend. Returns a fixed
/// [DashboardStats] payload so screens render without a network.
class FakeDashboardGateway implements DashboardGateway {
  FakeDashboardGateway({DashboardStats? stats})
    : stats =
          stats ??
          const DashboardStats(
            totalStudents: 128,
            totalCertificates: 342,
            issuedToday: 7,
            verifiedCertificates: 299,
            pendingCertificates: 43,
          );

  DashboardStats stats;
  int fetchCalls = 0;

  @override
  Future<DashboardStats> fetchStats() async {
    fetchCalls++;
    return stats;
  }
}

/// Builds a [Student] with defaults so tests read as intent, not boilerplate.
Student buildStudent({
  String id = 'student-1',
  String studentId = 'CS-2024-001',
  String name = 'Alice Johnson',
  String email = 'alice@university.edu',
  String department = 'Computer Science',
  String batch = '2024',
  String course = 'BSc Computer Science',
  String? phone,
}) {
  return Student(
    id: id,
    studentId: studentId,
    name: name,
    email: email,
    department: department,
    batch: batch,
    course: course,
    phone: phone,
    createdAt: DateTime(2024, 1, 10),
  );
}

/// A small, deterministic directory used by most student widget tests.
List<Student> defaultStudents() => [
  buildStudent(
    id: 'student-1',
    studentId: 'CS-2024-001',
    name: 'Alice Johnson',
    email: 'alice@university.edu',
    department: 'Computer Science',
    batch: '2024',
    course: 'BSc Computer Science',
  ),
  buildStudent(
    id: 'student-2',
    studentId: 'EE-2024-014',
    name: 'Bob Smith',
    email: 'bob@university.edu',
    department: 'Electrical Engineering',
    batch: '2024',
    course: 'BEng Electrical',
  ),
  buildStudent(
    id: 'student-3',
    studentId: 'PHY-2023-007',
    name: 'Carol White',
    email: 'carol@university.edu',
    department: 'Physics',
    batch: '2023',
    course: 'BSc Physics',
  ),
];

/// In-memory implementation of the student backend with server-like behavior:
/// case-insensitive search over name/roll/email, exact department match,
/// alphabetical sort, and page slicing.
class FakeStudentGateway implements StudentGateway {
  FakeStudentGateway({List<Student>? seed, this.failWith})
    : _students = [...?seed];

  final List<Student> _students;
  ApiException? failWith;
  int fetchCalls = 0;
  int _createdCount = 0;

  @override
  Future<Paginated<Student>> fetchStudents({
    required int page,
    required int pageSize,
    String? search,
    String? department,
  }) async {
    if (failWith != null) throw failWith!;
    fetchCalls++;

    var filtered = List<Student>.of(_students);
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      filtered = filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(query) ||
                s.studentId.toLowerCase().contains(query) ||
                s.email.toLowerCase().contains(query),
          )
          .toList();
    }
    if (department != null && department.isNotEmpty) {
      filtered = filtered.where((s) => s.department == department).toList();
    }
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final total = filtered.length;
    final totalPages = total == 0 ? 0 : (total / pageSize).ceil();
    final start = (page - 1) * pageSize;
    if (start >= total) {
      return Paginated(
        items: const [],
        total: total,
        page: page,
        pageSize: pageSize,
        totalPages: totalPages,
      );
    }
    final end = (start + pageSize) > total ? total : start + pageSize;
    return Paginated(
      items: filtered.sublist(start, end),
      total: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<Student> fetchStudent(String id) async {
    if (failWith != null) throw failWith!;
    return _students.firstWhere(
      (s) => s.id == id,
      orElse: () => throw ApiException.notFound('Student not found.'),
    );
  }

  @override
  Future<Student> createStudent(StudentDraft draft) async {
    if (failWith != null) throw failWith!;
    _createdCount++;
    final student = Student(
      id: 'student-new-$_createdCount',
      studentId: draft.studentId,
      name: draft.name,
      email: draft.email,
      department: draft.department,
      batch: draft.batch,
      course: draft.course,
      phone: draft.phone,
      profilePhotoUrl: draft.profilePhotoUrl,
      createdAt: DateTime.now(),
    );
    _students.add(student);
    return student;
  }

  @override
  Future<Student> updateStudent(String id, StudentDraft draft) async {
    if (failWith != null) throw failWith!;
    final index = _students.indexWhere((s) => s.id == id);
    if (index == -1) throw ApiException.notFound('Student not found.');
    final existing = _students[index];
    final updated = Student(
      id: id,
      studentId: draft.studentId,
      name: draft.name,
      email: draft.email,
      department: draft.department,
      batch: draft.batch,
      course: draft.course,
      phone: draft.phone,
      profilePhotoUrl: draft.profilePhotoUrl,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _students[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteStudent(String id) async {
    if (failWith != null) throw failWith!;
    _students.removeWhere((s) => s.id == id);
  }
}

/// Builds a [Certificate] with defaults so tests read as intent, not
/// boilerplate.
Certificate buildCertificate({
  String id = 'cert-1',
  String uid = 'CERT-2026-000001',
  String studentId = 'student-1',
  String studentName = 'Alice Johnson',
  String title = 'BSc Computer Science',
  CertificateStatus status = CertificateStatus.issued,
  String? transactionHash =
      '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1f3b6776c3d0b7f2c2c39d4a11',
  String? chain = 'polygon-mumbai',
  int? blockNumber = 4829102,
}) {
  return Certificate(
    id: id,
    uid: uid,
    studentId: studentId,
    studentName: studentName,
    title: title,
    status: status,
    issuedAt: DateTime(2026, 3, 10),
    issuerName: 'CertoSec University Network',
    transactionHash: transactionHash,
    chain: chain,
    blockNumber: blockNumber,
  );
}

/// A small, deterministic certificate ledger used by certificate tests.
List<Certificate> defaultCertificates() => [
  buildCertificate(
    id: 'cert-1',
    uid: 'CERT-2026-000001',
    studentId: 'student-1',
    studentName: 'Alice Johnson',
    title: 'BSc Computer Science',
  ),
  buildCertificate(
    id: 'cert-2',
    uid: 'CERT-2026-000002',
    studentId: 'student-2',
    studentName: 'Bob Smith',
    title: 'BEng Electrical',
    status: CertificateStatus.pending,
  ),
  buildCertificate(
    id: 'cert-3',
    uid: 'CERT-2026-000003',
    studentId: 'student-3',
    studentName: 'Carol White',
    title: 'BSc Physics',
    status: CertificateStatus.verified,
  ),
];

/// In-memory implementation of the certificate backend with server-like
/// behavior: case-insensitive search over uid/student name, exact status
/// match, and page slicing.
class FakeCertificateGateway implements CertificateGateway {
  FakeCertificateGateway({List<Certificate>? seed})
    : _certificates = [...?seed];

  final List<Certificate> _certificates;
  int fetchCalls = 0;
  int issueCalls = 0;

  @override
  Future<Paginated<Certificate>> fetchCertificates({
    required int page,
    required int pageSize,
    String? search,
    String? status,
  }) async {
    fetchCalls++;

    var filtered = List<Certificate>.of(_certificates);
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      filtered = filtered
          .where(
            (c) =>
                c.uid.toLowerCase().contains(query) ||
                c.studentName.toLowerCase().contains(query),
          )
          .toList();
    }
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((c) => c.status.name == status).toList();
    }

    final total = filtered.length;
    final totalPages = total == 0 ? 0 : (total / pageSize).ceil();
    final start = (page - 1) * pageSize;
    if (start >= total) {
      return Paginated(
        items: const [],
        total: total,
        page: page,
        pageSize: pageSize,
        totalPages: totalPages,
      );
    }
    final end = (start + pageSize) > total ? total : start + pageSize;
    return Paginated(
      items: filtered.sublist(start, end),
      total: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<Certificate> fetchCertificate(String uid) async {
    return _certificates.firstWhere(
      (c) => c.uid == uid,
      orElse: () => throw ApiException.notFound('Certificate not found.'),
    );
  }

  @override
  Future<Certificate> issueCertificate(CertificateDraft draft) async {
    issueCalls++;
    final certificate = Certificate(
      id: 'cert-new-${_certificates.length + 1}',
      uid: 'CERT-2026-${(_certificates.length + 1).toString().padLeft(6, '0')}',
      studentId: draft.studentId,
      studentName: _studentNameFor(draft.studentId),
      title: draft.title,
      description: draft.description,
      status: CertificateStatus.issued,
      issuedAt: DateTime.now(),
      issuerName: 'CertoSec University Network',
      transactionHash:
          '0x9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f1a',
      chain: 'polygon-mumbai',
      blockNumber: 4831200,
    );
    _certificates.insert(0, certificate);
    return certificate;
  }

  String _studentNameFor(String studentId) {
    for (final student in defaultStudents()) {
      if (student.id == studentId) return student.name;
    }
    return 'Student';
  }
}

/// In-memory implementation of the public verification backend. Any UID in
/// the known set verifies as authentic; everything else is invalid. The same
/// contract applies to transaction hashes.
class FakeVerificationGateway implements VerificationGateway {
  FakeVerificationGateway({Set<String>? validUids, Set<String>? validHashes})
    : _validUids = validUids ?? {'CERT-2026-000001', 'CERT-2026-000003'},
      _validHashes =
          validHashes ?? {
            '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1f3b6776c3d0b7f2c2c39d4a11',
          };

  final Set<String> _validUids;
  final Set<String> _validHashes;
  int verifyCalls = 0;
  int verifyHashCalls = 0;

  @override
  Future<VerificationResult> verifyByUid(String uid) async {
    verifyCalls++;
    if (_validUids.contains(uid)) {
      return _validResult(uid);
    }
    return VerificationResult(
      uid: uid,
      status: VerificationStatus.invalid,
      message: 'No matching certificate was found. The UID may be incorrect.',
    );
  }

  @override
  Future<VerificationResult> verifyByTxHash(String txHash) async {
    verifyHashCalls++;
    if (_validHashes.contains(txHash)) {
      return _validResult('CERT-2026-000001', transactionHash: txHash);
    }
    return VerificationResult(
      uid: '',
      status: VerificationStatus.invalid,
      message: 'No matching certificate was found. The hash may be incorrect.',
    );
  }

  VerificationResult _validResult(String uid, {String? transactionHash}) {
    return VerificationResult(
      uid: uid,
      status: VerificationStatus.valid,
      message: 'This certificate is authentic.',
      studentName: 'Alice Johnson',
      certificateTitle: 'BSc Computer Science',
      issuedAt: DateTime(2026, 3, 10),
      transactionHash:
          transactionHash ??
          '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1f3b6776c3d0b7f2c2c39d4a11',
      verifiedAt: DateTime(2026, 3, 11),
    );
  }
}
