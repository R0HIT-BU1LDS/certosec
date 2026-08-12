import '../../models/verification_result.dart';

/// VerificationGateway is the contract for the public certificate
/// verification backend. It requires no authentication.
abstract interface class VerificationGateway {
  /// Verifies a certificate by its public UID and returns the verdict.
  Future<VerificationResult> verifyByUid(String uid);

  /// Verifies a certificate by its on-chain transaction hash and returns the
  /// verdict. The hash is a 0x-prefixed 64-character hex string.
  Future<VerificationResult> verifyByTxHash(String txHash);
}
