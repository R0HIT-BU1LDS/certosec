import '../core/constants/app_enums.dart';
import '../core/utils/model_utils.dart';

/// VerificationResult is the verdict returned by the public verification
/// endpoint for a submitted certificate UID.
///
/// A [valid] verdict means the certificate exists, is in an issued state, and
/// its hash matches what was recorded on the blockchain.
class VerificationResult {
  const VerificationResult({
    required this.uid,
    required this.status,
    required this.message,
    this.studentName,
    this.certificateTitle,
    this.issuedAt,
    this.transactionHash,
    this.verifiedAt,
  });

  final String uid;
  final VerificationStatus status;
  final String message;
  final String? studentName;
  final String? certificateTitle;
  final DateTime? issuedAt;
  final String? transactionHash;
  final DateTime? verifiedAt;

  /// Convenience flag: did this certificate verify as authentic?
  bool get isValid => status == VerificationStatus.valid;

  /// Parses a verification response. Accepts nested (`certificate`) or flat
  /// payloads and the usual snake_case / camelCase key variations.
  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    final certificate =
        ModelUtils.pickMap(json, ['certificate']) ?? const <String, dynamic>{};
    final status = VerificationStatus.fromJson(
      ModelUtils.pick(json, ['status', 'verificationStatus']),
    );

    return VerificationResult(
      uid:
          ModelUtils.pick(json, ['uid', 'certificateUid'])?.toString() ??
          ModelUtils.pick(certificate, ['uid', 'certificateUid'])?.toString() ??
          '',
      status: status,
      message:
          ModelUtils.pick(json, ['message', 'detail'])?.toString() ??
          _messageFor(status),
      studentName:
          ModelUtils.pick(json, ['studentName', 'student_name'])?.toString() ??
          ModelUtils.pick(certificate, [
            'studentName',
            'student_name',
            'recipientName',
          ])?.toString(),
      certificateTitle:
          ModelUtils.pick(json, ['certificateTitle', 'certificate_title'])
              ?.toString() ??
          ModelUtils.pick(certificate, [
            'title',
            'certificateName',
            'certificate_name',
          ])?.toString(),
      issuedAt: ModelUtils.pickDate(
        json,
        ['issuedAt', 'issued_at', 'issuedOn'],
      ) ??
          ModelUtils.pickDate(certificate, [
            'issuedAt',
            'issued_at',
            'issuedOn',
          ]),
      transactionHash:
          ModelUtils.pick(json, ['transactionHash', 'transaction_hash'])
              ?.toString() ??
          ModelUtils.pick(certificate, [
            'transactionHash',
            'transaction_hash',
            'hash',
          ])?.toString(),
      verifiedAt: ModelUtils.pickDate(
        json,
        ['verifiedAt', 'verified_at'],
      ),
    );
  }

  static String _messageFor(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.valid =>
        'This certificate is authentic and matches the blockchain record.',
      VerificationStatus.invalid =>
        'No matching certificate was found. The UID may be incorrect.',
      VerificationStatus.tampered =>
        'This certificate has been altered and cannot be trusted.',
    };
  }
}
