import '../models/certificate.dart';
import '../models/pagination.dart';
import '../services/api/certificate_gateway.dart';

/// CertificateRepository is the single orchestrator for certificate business
/// rules. It is intentionally thin today but gives cross-cutting concerns
/// (caching, audit logging) a stable home that screens never bypass.
class CertificateRepository {
  CertificateRepository({required CertificateGateway gateway})
      : _gateway = gateway;

  final CertificateGateway _gateway;

  Future<Paginated<Certificate>> fetchCertificates({
    required int page,
    required int pageSize,
    String? search,
    String? status,
  }) {
    return _gateway.fetchCertificates(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );
  }

  Future<Certificate> fetchCertificate(String uid) =>
      _gateway.fetchCertificate(uid);

  Future<Certificate> issueCertificate(CertificateDraft draft) =>
      _gateway.issueCertificate(draft);
}
