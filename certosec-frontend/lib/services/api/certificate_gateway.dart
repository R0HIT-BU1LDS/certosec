import '../../models/certificate.dart';
import '../../models/pagination.dart';

/// CertificateGateway is the contract for the certificate management backend.
///
/// Screens depend on this interface, never on the HTTP implementation
/// directly, so tests can substitute an in-memory fake.
abstract interface class CertificateGateway {
  /// Fetches one page of certificates. [search] matches against the uid or
  /// recipient name; [status] is an exact match. Either may be null.
  Future<Paginated<Certificate>> fetchCertificates({
    required int page,
    required int pageSize,
    String? search,
    String? status,
  });

  Future<Certificate> fetchCertificate(String uid);

  Future<Certificate> issueCertificate(CertificateDraft draft);
}
