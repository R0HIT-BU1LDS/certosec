import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/config/app_config.dart';
import '../../models/certificate.dart';
import '../../models/student.dart';
import '../../models/verification_result.dart';

/// The fields rendered on a certificate PDF. Kept as plain data so the layout
/// stays a pure function and the same document can be produced from an admin
/// [Certificate] or a public [VerificationResult].
class CertificatePdfDocument {
  const CertificatePdfDocument({
    required this.studentName,
    required this.studentId,
    required this.course,
    required this.department,
    required this.batch,
    required this.uid,
    required this.issuerName,
    this.issuedAt,
    this.transactionHash,
    this.chain,
    this.blockNumber,
    required this.verificationUrl,
  });

  factory CertificatePdfDocument.fromCertificate(
    Certificate certificate, {
    Student? student,
  }) {
    return CertificatePdfDocument(
      studentName: certificate.studentName,
      studentId: certificate.studentId,
      course: certificate.title,
      department: student?.department ?? '',
      batch: student?.batch ?? '',
      uid: certificate.uid,
      issuerName: certificate.issuerName ?? AppConfig.orgName,
      issuedAt: certificate.issuedAt,
      transactionHash: certificate.transactionHash,
      chain: certificate.chain,
      blockNumber: certificate.blockNumber,
      verificationUrl: certificate.verificationUrl,
    );
  }

  factory CertificatePdfDocument.fromVerificationResult(
    VerificationResult result,
  ) {
    return CertificatePdfDocument(
      studentName: result.studentName ?? '',
      studentId: '',
      course: result.certificateTitle ?? '',
      department: '',
      batch: '',
      uid: result.uid,
      issuerName: AppConfig.orgName,
      issuedAt: result.issuedAt,
      transactionHash: result.transactionHash,
      verificationUrl: result.uid.isEmpty
          ? ''
          : '${AppConfig.verificationBaseUrl}?uid=${result.uid}',
    );
  }

  final String studentName;
  final String studentId;
  final String course;
  final String department;
  final String batch;
  final String uid;
  final String issuerName;
  final DateTime? issuedAt;
  final String? transactionHash;
  final String? chain;
  final int? blockNumber;
  final String verificationUrl;
}

/// CertificatePdfService renders a professional landscape-A4 certificate PDF
/// and hands it to the platform share sheet for downloading.
///
/// The layout mirrors the on-screen certificate preview: institution header,
/// student details, the shareable QR code (which contains only the
/// verification URL + UID), the on-chain proof, a signature placeholder, and
/// verification instructions.
class CertificatePdfService {
  /// Builds the PDF and opens the system share sheet so the user can save or
  /// print it.
  Future<void> shareCertificate(CertificatePdfDocument document) async {
    final bytes = await buildCertificatePdf(document);
    final safeUid = document.uid.isEmpty ? 'certificate' : document.uid;
    await Printing.sharePdf(
      bytes: bytes,
      filename: '$safeUid.pdf',
      subject: '$safeUid certificate',
    );
  }

  /// Produces the PDF bytes. Pure — safe to call from unit tests.
  Future<Uint8List> buildCertificatePdf(CertificatePdfDocument document) async {
    final pdf = pw.Document(
      title: 'Certificate ${document.uid}',
      author: document.issuerName,
      creator: AppConfig.appName,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFF1A3E6E),
              width: 3,
            ),
          ),
          padding: const pw.EdgeInsets.fromLTRB(28, 22, 28, 22),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(document),
              pw.SizedBox(height: 18),
              pw.Expanded(child: _body(context, document)),
              _footer(context, document),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _header(CertificatePdfDocument document) {
    return pw.Column(
      children: [
        pw.Text(
          document.issuerName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF1A3E6E),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          AppConfig.appTagline,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          height: 2,
          color: PdfColor.fromInt(0xFF1A3E6E),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'CERTIFICATE OF ACHIEVEMENT',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 3,
            color: PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  pw.Widget _body(pw.Context context, CertificatePdfDocument document) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 3, child: _leftPanel(document)),
        pw.SizedBox(width: 24),
        pw.Expanded(flex: 2, child: _rightPanel(document)),
      ],
    );
  }

  pw.Widget _leftPanel(CertificatePdfDocument document) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'This certificate is proudly presented to',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          _or(document.studentName, 'N/A'),
          style: pw.TextStyle(
            fontSize: 30,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'in recognition of successfully completing the course',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _or(document.course, 'N/A'),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF1A3E6E),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _joined(['Department of ${_or(document.department, 'N/A')}',
            'Batch ${_or(document.batch, 'N/A')}']),
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 18),
        _detailRow('Student ID', _or(document.studentId, 'N/A')),
        _detailRow(
          'Issued on',
          document.issuedAt == null
              ? 'N/A'
              : '${document.issuedAt!.year}-'
                    '${document.issuedAt!.month.toString().padLeft(2, '0')}-'
                    '${document.issuedAt!.day.toString().padLeft(2, '0')}',
        ),
        _detailRow('Certificate UID', _or(document.uid, 'N/A')),
        if (document.transactionHash != null) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'BLOCKCHAIN PROOF',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.4,
              color: PdfColor.fromInt(0xFF1E7A4A),
            ),
          ),
          _detailRow('Transaction hash', document.transactionHash!),
          if (document.chain != null || document.blockNumber != null)
            _detailRow(
              'Network',
              _joined([
                if (document.chain != null) document.chain!,
                if (document.blockNumber != null)
                  'Block ${document.blockNumber}',
              ]),
            ),
        ],
      ],
    );
  }

  pw.Widget _rightPanel(CertificatePdfDocument document) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: document.verificationUrl.isEmpty
                ? pw.SizedBox(
                    width: 110,
                    height: 110,
                    child: pw.Center(
                      child: pw.Text(
                        'QR generated on issuance',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  )
                : pw.BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: document.verificationUrl,
                    width: 110,
                    height: 110,
                    color: PdfColors.black,
                    drawText: false,
                  ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Scan to verify',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          document.verificationUrl.isEmpty
              ? 'Verification URL assigned on issuance'
              : document.verificationUrl,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _footer(pw.Context context, CertificatePdfDocument document) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400, thickness: 0.8),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 200,
                  child: pw.Container(
                    height: 1,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Authorised Signatory',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  document.issuerName,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1A3E6E),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  AppConfig.appTagline,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Verify this certificate by scanning the QR code or by entering its '
          'UID or transaction hash at ${document.verificationUrl.isEmpty ? AppConfig.verificationBaseUrl : ''}',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  static String _or(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value.trim();

  static String _joined(List<String> parts) =>
      parts.where((p) => p.isNotEmpty).join('  |  ');
}
