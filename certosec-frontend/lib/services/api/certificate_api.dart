import '../../models/certificate.dart';
import '../../models/pagination.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'certificate_gateway.dart';

/// CertificateApi is the HTTP implementation of [CertificateGateway].
///
///   GET    /certificates?page=&pageSize=&search=&status=
///   GET    /certificates/:uid
///   POST   /certificates/issue
class CertificateApi implements CertificateGateway {
  CertificateApi(this._client);

  final ApiClient _client;

  @override
  Future<Paginated<Certificate>> fetchCertificates({
    required int page,
    required int pageSize,
    String? search,
    String? status,
  }) async {
    final response = await _client.get(
      ApiEndpoints.certificates,
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return Paginated.fromJson(
      response.data! as Map<String, dynamic>,
      Certificate.fromJson,
    );
  }

  @override
  Future<Certificate> fetchCertificate(String uid) async {
    final response = await _client.get(ApiEndpoints.certificate(uid));
    return Certificate.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<Certificate> issueCertificate(CertificateDraft draft) async {
    final response = await _client.post(
      ApiEndpoints.issueCertificate,
      body: draft.toJson(),
    );
    return Certificate.fromJson(response.data! as Map<String, dynamic>);
  }
}
