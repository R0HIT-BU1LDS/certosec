import 'package:certosec/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppValidators.email', () {
    test('accepts well-formed addresses', () {
      expect(AppValidators.email('admin@university.edu'), isNull);
      expect(AppValidators.email('a.b+c@sub.domain.co'), isNull);
    });

    test('rejects malformed addresses', () {
      expect(AppValidators.email(''), isNotNull);
      expect(AppValidators.email('plainaddress'), isNotNull);
      expect(AppValidators.email('a@b'), isNotNull);
      expect(AppValidators.email('a b@c.com'), isNotNull);
      expect(AppValidators.email('@nodomain.com'), isNotNull);
    });
  });

  group('AppValidators.password', () {
    test('accepts passwords of at least 8 characters', () {
      expect(AppValidators.password('password123'), isNull);
      expect(AppValidators.password('12345678'), isNull);
    });

    test('rejects short or empty passwords', () {
      expect(AppValidators.password(''), isNotNull);
      expect(AppValidators.password('1234567'), isNotNull);
    });
  });

  group('AppValidators.certificateUid', () {
    test('accepts CERT-YYYY-NNNNNN format (case-insensitive)', () {
      expect(AppValidators.certificateUid('CERT-2026-000001'), isNull);
      expect(AppValidators.certificateUid('cert-2026-123456'), isNull);
    });

    test('rejects malformed UIDs', () {
      expect(AppValidators.certificateUid('CERT-2026-1'), isNotNull);
      expect(AppValidators.certificateUid('CERT-26-000001'), isNotNull);
      expect(AppValidators.certificateUid('ABC-2026-000001'), isNotNull);
      expect(AppValidators.certificateUid('CERT-2026-000001-extra'), isNotNull);
    });
  });

  group('AppValidators.ethereumTransactionHash', () {
    test('accepts 0x followed by 64 hex characters', () {
      expect(AppValidators.ethereumTransactionHash('0x${'a' * 64}'), isNull);
      expect(
        AppValidators.ethereumTransactionHash('0x${'A' * 32}${'b' * 32}'),
        isNull,
      );
    });

    test('rejects malformed hashes', () {
      expect(AppValidators.ethereumTransactionHash('0x${'a' * 63}'), isNotNull);
      expect(AppValidators.ethereumTransactionHash('a' * 64), isNotNull);
      expect(AppValidators.ethereumTransactionHash('0x${'g' * 64}'), isNotNull);
      expect(AppValidators.ethereumTransactionHash(''), isNotNull);
    });
  });

  group('AppValidators.formatCertificateUidInput', () {
    test('formats typing into the CERT-YYYY-NNNNNN skeleton', () {
      expect(AppValidators.formatCertificateUidInput('cert'), 'CERT');
      expect(AppValidators.formatCertificateUidInput('CERT2026'), 'CERT-2026');
      expect(
        AppValidators.formatCertificateUidInput('cert2026000001'),
        'CERT-2026-000001',
      );
      expect(
        AppValidators.formatCertificateUidInput('cert 2026 000001!'),
        'CERT-2026-000001',
      );
    });
  });

  group('AppValidators.studentId', () {
    test('accepts roll numbers of letters, digits, and dashes', () {
      expect(AppValidators.studentId('CS-2024-001'), isNull);
      expect(AppValidators.studentId('ee2024014'), isNull);
    });

    test('rejects empty, too-short, or symbol-laden values', () {
      expect(AppValidators.studentId(''), isNotNull);
      expect(AppValidators.studentId('ab'), isNotNull);
      expect(AppValidators.studentId('CS 2024 001'), isNotNull);
      expect(AppValidators.studentId('CS_2024_001'), isNotNull);
    });
  });

  group('AppValidators.batchYear', () {
    test('accepts four-digit years in range', () {
      expect(AppValidators.batchYear('2024'), isNull);
      expect(AppValidators.batchYear('2099'), isNull);
    });

    test('rejects non-years', () {
      expect(AppValidators.batchYear(''), isNotNull);
      expect(AppValidators.batchYear('twenty-four'), isNotNull);
      expect(AppValidators.batchYear('1999'), isNotNull);
      expect(AppValidators.batchYear('24'), isNotNull);
    });
  });

  group('AppValidators.course', () {
    test('accepts course names of at least 2 characters', () {
      expect(AppValidators.course('BSc Computer Science'), isNull);
      expect(AppValidators.course('BSc'), isNull);
    });

    test('rejects empty or single-character courses', () {
      expect(AppValidators.course(''), isNotNull);
      expect(AppValidators.course('A'), isNotNull);
    });
  });

  group('AppValidators.optionalPhone', () {
    test('accepts empty values and plausible phone numbers', () {
      expect(AppValidators.optionalPhone(''), isNull);
      expect(AppValidators.optionalPhone('  '), isNull);
      expect(AppValidators.optionalPhone('+1 555 010 2030'), isNull);
      expect(AppValidators.optionalPhone('555-010-2030'), isNull);
    });

    test('rejects implausible phone numbers', () {
      expect(AppValidators.optionalPhone('123'), isNotNull);
      expect(AppValidators.optionalPhone('abc12345678'), isNotNull);
    });
  });
}
