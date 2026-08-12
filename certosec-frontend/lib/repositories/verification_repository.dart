import '../models/verification_result.dart';
import '../services/api/verification_gateway.dart';

/// VerificationRepository is the single orchestrator for public certificate
/// verification. It is intentionally thin today but exists so that caching or
/// offline verification queues have a stable home later.
class VerificationRepository {
  VerificationRepository({required VerificationGateway gateway})
      : _gateway = gateway;

  final VerificationGateway _gateway;

  Future<VerificationResult> verifyByUid(String uid) =>
      _gateway.verifyByUid(uid);

  Future<VerificationResult> verifyByTxHash(String txHash) =>
      _gateway.verifyByTxHash(txHash);
}
