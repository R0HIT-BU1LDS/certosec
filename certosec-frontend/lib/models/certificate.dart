import '../core/config/app_config.dart';
import '../core/constants/app_enums.dart';
import '../core/utils/model_utils.dart';

/// Certificate is a blockchain-backed certificate issued to a student.
///
/// The certificate carries a stable public `uid` (e.g. `CERT-2026-000123`)
/// which is encoded into a QR code; anyone can verify the certificate by
/// submitting that UID to the public verification endpoint.
class Certificate {
  const Certificate({
    required this.id,
    required this.uid,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.status,
    this.description,
    this.issuedAt,
    this.issuerName,
    this.transactionHash,
    this.chain,
    this.blockNumber,
  });

  final String id;
  final String uid;
  final String studentId;
  final String studentName;
  final String title;
  final CertificateStatus status;
  final String? description;
  final DateTime? issuedAt;
  final String? issuerName;
  final String? transactionHash;
  final String? chain;
  final int? blockNumber;

  /// The shareable verification URL encoded into the QR code.
  String get verificationUrl => '${AppConfig.verificationBaseUrl}?uid=$uid';

  /// Parses a certificate. Key names are accepted leniently so both the local
  /// backend and a future production API can feed this model.
  factory Certificate.fromJson(Map<String, dynamic> json) {
    final uid =
        ModelUtils.pick(json, ['uid', 'certificateUid', 'certificate_uid'])
                ?.toString() ??
            '';
    if (uid.isEmpty) {
      throw const FormatException('Certificate did not contain a uid.');
    }

    final student =
        ModelUtils.pickMap(json, ['student']) ?? const <String, dynamic>{};

    return Certificate(
      id: ModelUtils.pick(json, ['id'])?.toString() ?? uid,
      uid: uid,
      studentId: ModelUtils.pick(json, ['studentId', 'student_id'])?.toString() ??
          ModelUtils.pick(student, ['id'])?.toString() ??
          '',
      studentName:
          ModelUtils.pick(json, [
            'studentName',
            'student_name',
            'recipientName',
            'recipient_name',
          ])?.toString() ??
          ModelUtils.pick(student, ['name', 'fullName'])?.toString() ??
          '',
      title:
          ModelUtils.pick(json, [
            'title',
            'certificateName',
            'certificate_name',
            'name',
          ])?.toString() ??
          '',
      description:
          ModelUtils.pick(json, ['description', 'details'])?.toString(),
      status: CertificateStatus.fromJson(ModelUtils.pick(json, ['status'])),
      issuedAt: ModelUtils.pickDate(
        json,
        ['issuedAt', 'issued_at', 'issuedOn', 'issued_on'],
      ),
      issuerName:
          ModelUtils.pick(json, ['issuerName', 'issuer_name', 'issuedBy'])
              ?.toString(),
      transactionHash:
          ModelUtils.pick(json, [
            'transactionHash',
            'transaction_hash',
            'txHash',
            'hash',
          ])?.toString(),
      chain: ModelUtils.pick(json, ['chain', 'blockchain', 'network'])
          ?.toString(),
      blockNumber: _parseBlockNumber(
        ModelUtils.pick(json, ['blockNumber', 'block_number']),
      ),
    );
  }

  static int? _parseBlockNumber(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// CertificateDraft is the payload used to request a new certificate. The
/// server assigns the uid, issued date, issuer, and blockchain proof.
class CertificateDraft {
  const CertificateDraft({
    required this.studentId,
    required this.title,
    this.description,
  });

  final String studentId;
  final String title;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }
}
