import 'package:certosec/core/constants/app_enums.dart';
import 'package:certosec/models/certificate.dart';
import 'package:certosec/providers/certificates_provider.dart';
import 'package:certosec/repositories/certificate_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late CertificatesProvider provider;

  CertificatesProvider buildProvider(FakeCertificateGateway gateway) {
    return CertificatesProvider(CertificateRepository(gateway: gateway));
  }

  tearDown(() {
    provider.dispose();
  });

  test('loadInitial populates the ledger and pagination metadata', () async {
    final gateway = FakeCertificateGateway(seed: defaultCertificates());
    provider = buildProvider(gateway);

    await provider.loadInitial();

    expect(provider.certificates, hasLength(3));
    expect(provider.total, 3);
    expect(provider.totalPages, 1);
    expect(provider.hasMore, isFalse);
    expect(provider.hasError, isFalse);
  });

  test('setSearch filters server-side and resets to page 1', () async {
    final gateway = FakeCertificateGateway(seed: defaultCertificates());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    await provider.setSearch('CERT-2026-000002');
    expect(provider.certificates, hasLength(1));
    expect(provider.certificates.single.title, 'BEng Electrical');

    await provider.setSearch('');
    expect(provider.certificates, hasLength(3));
  });

  test('setStatus narrows to the selected status', () async {
    final gateway = FakeCertificateGateway(seed: defaultCertificates());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    await provider.setStatus(CertificateStatus.pending);
    expect(provider.status, CertificateStatus.pending);
    expect(provider.certificates.single.uid, 'CERT-2026-000002');

    await provider.setStatus(null);
    expect(provider.certificates, hasLength(3));
  });

  test('issueCertificate merges the minted certificate into the ledger', () async {
    final gateway = FakeCertificateGateway(seed: defaultCertificates());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    const draft = CertificateDraft(
      studentId: 'student-1',
      title: 'MSc Data Science',
    );

    final certificate = await provider.issueCertificate(draft);
    expect(certificate, isNotNull);
    expect(certificate!.status, CertificateStatus.issued);
    expect(provider.certificates.first.uid, certificate.uid);
    expect(provider.total, 4);
  });

  test('fetchCertificate merges a deep-linked record into the cache', () async {
    final gateway = FakeCertificateGateway(seed: defaultCertificates());
    provider = buildProvider(gateway);

    expect(provider.certificateByUid('CERT-2026-000001'), isNull);
    await provider.fetchCertificate('CERT-2026-000001');
    expect(
      provider.certificateByUid('CERT-2026-000001')?.title,
      'BSc Computer Science',
    );
  });

  test('reload re-fetches the current page', () async {
    final gateway = FakeCertificateGateway(seed: defaultCertificates());
    provider = buildProvider(gateway);
    await provider.loadInitial();

    await provider.reload();
    expect(provider.certificates, hasLength(3));
    expect(gateway.fetchCalls, 2);
  });
}
