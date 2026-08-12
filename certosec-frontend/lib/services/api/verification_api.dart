import '../../models/verification_result.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'verification_gateway.dart';

/// VerificationApi is the HTTP implementation of [VerificationGateway].
///
///   GET /verify?uid=CERT-2026-000001
///   GET /verify?txHash=0x...
class VerificationApi implements VerificationGateway {
  VerificationApi(this._client);

  final ApiClient _client;

  @override
  Future<VerificationResult> verifyByUid(String uid) async {
    final response = await _client.get(
      ApiEndpoints.verify,
      queryParameters: {'uid': uid},
    );
    return VerificationResult.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<VerificationResult> verifyByTxHash(String txHash) async {
    final response = await _client.get(
      ApiEndpoints.verify,
      queryParameters: {'txHash': txHash},
    );
    return VerificationResult.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }
}
