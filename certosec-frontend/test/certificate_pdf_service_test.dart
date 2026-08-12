import 'dart:typed_data';

import 'package:certosec/core/constants/app_enums.dart';
import 'package:certosec/models/certificate.dart';
import 'package:certosec/models/verification_result.dart';
import 'package:certosec/services/pdf/certificate_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = CertificatePdfService();

  group('CertificatePdfService.buildCertificatePdf', () {
    test('produces a valid PDF header', () async {
      final document = CertificatePdfDocument(
        studentName: 'Ada Lovelace',
        studentId: 'STU-2024-001',
        course: 'Applied Cryptography',
        department: 'Computer Science',
        batch: '2024',
        uid: 'CERT-ABC-123',
        issuerName: 'CertoSec University Network',
        issuedAt: DateTime.utc(2026, 8, 12),
        transactionHash: '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1f3b6776c3d0b7f2c2c39d4a11',
        chain: 'Sepolia',
        blockNumber: 18446744,
        verificationUrl: 'https://verify.certosec.com/?uid=CERT-ABC-123',
      );

      final bytes = await service.buildCertificatePdf(document);

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('renders placeholders when issued data is missing', () async {
      final result = VerificationResult(
        uid: '',
        status: VerificationStatus.valid,
        message: 'ok',
      );

      final bytes = await service.buildCertificatePdf(
        CertificatePdfDocument.fromVerificationResult(result),
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
