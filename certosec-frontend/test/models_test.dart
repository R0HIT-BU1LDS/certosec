import 'package:certosec/core/constants/app_enums.dart';
import 'package:certosec/models/certificate.dart';
import 'package:certosec/models/dashboard_stats.dart';
import 'package:certosec/models/pagination.dart';
import 'package:certosec/models/student.dart';
import 'package:certosec/models/student_draft.dart';
import 'package:certosec/models/verification_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Student.fromJson', () {
    test('parses camelCase response shape', () {
      final student = Student.fromJson({
        'id': 'student-1',
        'studentId': 'CS-2024-001',
        'name': 'Alice Johnson',
        'email': 'alice@university.edu',
        'department': 'Computer Science',
        'batch': '2024',
        'course': 'BSc Computer Science',
        'phone': '+1 555 010 2030',
        'createdAt': '2024-01-10T09:30:00Z',
      });

      expect(student.id, 'student-1');
      expect(student.studentId, 'CS-2024-001');
      expect(student.name, 'Alice Johnson');
      expect(student.phone, '+1 555 010 2030');
      expect(student.createdAt, isNotNull);
      expect(student.updatedAt, isNull);
    });

    test('parses snake_case response shape', () {
      final student = Student.fromJson({
        'id': 'student-2',
        'student_id': 'EE-2024-014',
        'full_name': 'Bob Smith',
        'email': 'bob@university.edu',
        'department': 'Electrical Engineering',
        'cohort': '2024',
        'program': 'BEng Electrical',
      });

      expect(student.studentId, 'EE-2024-014');
      expect(student.name, 'Bob Smith');
      expect(student.batch, '2024');
      expect(student.course, 'BEng Electrical');
    });

    test('missing fields fall back to empty values without throwing', () {
      final student = Student.fromJson(const {'id': 'x'});
      expect(student.name, isEmpty);
      expect(student.email, isEmpty);
      expect(student.department, isEmpty);
    });
  });

  group('StudentDraft', () {
    test('toJson omits null optional fields', () {
      final json = const StudentDraft(
        studentId: 'CS-2024-001',
        name: 'Alice Johnson',
        email: 'alice@university.edu',
        department: 'Computer Science',
        batch: '2024',
        course: 'BSc Computer Science',
      ).toJson();

      expect(json['studentId'], 'CS-2024-001');
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('profilePhotoUrl'), isFalse);
    });
  });

  group('Paginated.fromJson', () {
    test('parses the flat items shape', () {
      final page = Paginated.fromJson({
        'items': [
          {'id': 's1', 'name': 'A'},
          {'id': 's2', 'name': 'B'},
        ],
        'total': 42,
        'page': 1,
        'pageSize': 20,
        'totalPages': 3,
      }, (json) => Student.fromJson(json));

      expect(page.items, hasLength(2));
      expect(page.total, 42);
      expect(page.page, 1);
      expect(page.pageSize, 20);
      expect(page.totalPages, 3);
      expect(page.hasMore, isTrue);
    });

    test('parses the nested meta shape', () {
      final page = Paginated.fromJson({
        'data': [
          {'id': 's1', 'name': 'A'},
        ],
        'meta': {'total': 100, 'page': 2, 'pageSize': 50, 'pages': 2},
      }, (json) => Student.fromJson(json));

      expect(page.items, hasLength(1));
      expect(page.total, 100);
      expect(page.page, 2);
      expect(page.pageSize, 50);
      expect(page.totalPages, 2);
      expect(page.hasMore, isFalse);
    });

    test('falls back to sensible defaults when metadata is absent', () {
      final page = Paginated.fromJson({
        'items': [
          {'id': 's1', 'name': 'A'},
        ],
      }, (json) => Student.fromJson(json));

      expect(page.total, 1);
      expect(page.page, 1);
      expect(page.pageSize, 1);
      expect(page.totalPages, 1);
      expect(page.hasMore, isFalse);
    });

    test('handles empty pages', () {
      final page = Paginated.fromJson({
        'items': <Object>[],
        'total': 0,
        'page': 1,
        'pageSize': 20,
        'totalPages': 0,
      }, (json) => Student.fromJson(json));
      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });
  });

  group('DashboardStats.fromJson', () {
    test('parses camelCase counters', () {
      final stats = DashboardStats.fromJson({
        'totalStudents': 128,
        'totalCertificates': 342,
        'issuedToday': 7,
        'verifiedCertificates': 299,
        'pendingCertificates': 43,
      });
      expect(stats.totalStudents, 128);
      expect(stats.issuedToday, 7);
    });

    test('parses snake_case counters', () {
      final stats = DashboardStats.fromJson({
        'total_students': 5,
        'total_certificates': 9,
        'issued_today': 2,
        'verified_certificates': 8,
        'pending_certificates': 1,
      });
      expect(stats.totalStudents, 5);
      expect(stats.totalCertificates, 9);
      expect(stats.pendingCertificates, 1);
    });

    test('missing counters default to zero', () {
      final stats = DashboardStats.fromJson(const {});
      expect(stats.totalStudents, 0);
      expect(stats.verifiedCertificates, 0);
    });

    test('empty constructor is all zeros', () {
      const stats = DashboardStats.empty();
      expect(stats.totalStudents, 0);
      expect(stats.pendingCertificates, 0);
    });
  });

  group('Certificate.fromJson', () {
    test('parses a full camelCase certificate with nested student', () {
      final certificate = Certificate.fromJson({
        'id': 'cert-1',
        'uid': 'CERT-2026-000001',
        'student': {'id': 'student-1', 'name': 'Alice Johnson'},
        'title': 'BSc Computer Science',
        'description': 'Graduated with distinction.',
        'status': 'issued',
        'issuedAt': '2026-03-10T09:00:00Z',
        'issuerName': 'CertoSec University Network',
        'transactionHash': '0xabc123',
        'chain': 'polygon-mumbai',
        'blockNumber': 4829102,
      });

      expect(certificate.uid, 'CERT-2026-000001');
      expect(certificate.studentId, 'student-1');
      expect(certificate.studentName, 'Alice Johnson');
      expect(certificate.title, 'BSc Computer Science');
      expect(certificate.status, CertificateStatus.issued);
      expect(certificate.issuedAt, isNotNull);
      expect(certificate.transactionHash, '0xabc123');
      expect(certificate.blockNumber, 4829102);
    });

    test('parses a flat snake_case certificate', () {
      final certificate = Certificate.fromJson({
        'id': 'cert-2',
        'certificate_uid': 'CERT-2026-000002',
        'recipient_name': 'Bob Smith',
        'certificate_name': 'BEng Electrical',
        'status': 'PENDING',
        'issued_on': '2026-03-11T10:00:00Z',
      });

      expect(certificate.uid, 'CERT-2026-000002');
      expect(certificate.studentName, 'Bob Smith');
      expect(certificate.status, CertificateStatus.pending);
      expect(certificate.issuedAt, isNotNull);
    });

    test('unknown status falls back to pending', () {
      final certificate = Certificate.fromJson({
        'uid': 'CERT-2026-000003',
        'status': 'mystery',
      });
      expect(certificate.status, CertificateStatus.pending);
    });

    test('throws when the uid is missing', () {
      expect(
        () => Certificate.fromJson(const {'title': 'No uid here'}),
        throwsFormatException,
      );
    });

    test('verificationUrl embeds the uid', () {
      final certificate = Certificate.fromJson({
        'uid': 'CERT-2026-000001',
        'status': 'issued',
      });
      expect(
        certificate.verificationUrl,
        endsWith('?uid=CERT-2026-000001'),
      );
    });
  });

  group('CertificateDraft', () {
    test('toJson omits null and empty optional fields', () {
      final full = const CertificateDraft(
        studentId: 'student-1',
        title: 'BSc Physics',
        description: 'With distinction',
      ).toJson();
      expect(full['studentId'], 'student-1');
      expect(full['title'], 'BSc Physics');
      expect(full['description'], 'With distinction');

      final minimal = const CertificateDraft(
        studentId: 'student-1',
        title: 'BSc Physics',
      ).toJson();
      expect(minimal.containsKey('description'), isFalse);
    });
  });

  group('VerificationResult.fromJson', () {
    test('parses a valid nested payload', () {
      final result = VerificationResult.fromJson({
        'uid': 'CERT-2026-000001',
        'status': 'valid',
        'message': 'This certificate is authentic.',
        'certificate': {
          'studentName': 'Alice Johnson',
          'title': 'BSc Computer Science',
          'issuedAt': '2026-03-10T09:00:00Z',
          'transactionHash': '0xabc',
        },
        'verifiedAt': '2026-03-11T09:00:00Z',
      });

      expect(result.isValid, isTrue);
      expect(result.studentName, 'Alice Johnson');
      expect(result.certificateTitle, 'BSc Computer Science');
      expect(result.transactionHash, '0xabc');
      expect(result.verifiedAt, isNotNull);
    });

    test('parses a flat invalid payload and falls back to a default message', () {
      final result = VerificationResult.fromJson({
        'uid': 'CERT-2026-099999',
        'status': 'invalid',
      });

      expect(result.isValid, isFalse);
      expect(result.status, VerificationStatus.invalid);
      expect(result.message, isNotEmpty);
    });

    test('unknown status defaults to invalid', () {
      final result = VerificationResult.fromJson({
        'uid': 'CERT-2026-000001',
        'status': 'weird',
      });
      expect(result.status, VerificationStatus.invalid);
      expect(result.isValid, isFalse);
    });
  });
}
