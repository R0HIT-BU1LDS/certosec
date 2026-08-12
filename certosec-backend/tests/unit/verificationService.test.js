const VerificationService = require('../../src/services/verificationService');
const { calculateCertificateHash } = require('../../src/services/hashService');

const CONTRACT_ADDRESS = '0x0000000000000000000000000000000000000001';

function buildCertificate(overrides = {}) {
  const base = {
    id: '11111111-1111-4111-8111-111111111111',
    certificate_uid: 'CERT-2026-000001',
    student_uid: 'STU-2026-001',
    student_name: 'Ada Lovelace',
    title: 'Bachelor of Science in Computer Science',
    course: 'B.Sc. Computer Science',
    department: 'Computer Science',
    batch: '2026',
    issue_date: '2026-08-12',
    status: 'issued',
    transaction_hash: `0x${'a'.repeat(64)}`,
    issuer_address: '0x1234567890abcdef1234567890abcdef12345678',
    block_number: 42,
    network: 'Polygon Amoy',
  };
  const merged = { ...base, ...overrides };
  if (merged.certificate_hash === undefined || merged.certificate_hash === null) {
    merged.certificate_hash = hashOf(merged);
  }
  return merged;
}

function buildService({ certificate, onChainHash, tx, blockchainThrows = false } = {}) {
  const onChain = onChainHash !== undefined ? onChainHash : certificate ? certificate.certificate_hash : undefined;
  const certificateRepository = {
    findByUid: jest.fn().mockResolvedValue(certificate || null),
    findByTransactionHash: jest.fn().mockResolvedValue(certificate || null),
    update: jest.fn().mockResolvedValue({}),
  };
  const blockchainService = {
    getCertificate: jest.fn().mockImplementation(async () => {
      if (blockchainThrows) throw new Error('rpc down');
      return { exists: true, hash: onChain };
    }),
    getTransaction: jest.fn().mockResolvedValue(tx || null),
  };
  const auditService = {
    logRequest: jest.fn().mockResolvedValue(undefined),
  };
  const config = {
    blockchain: { contractAddress: CONTRACT_ADDRESS, networkName: 'Polygon Amoy' },
  };
  const service = new VerificationService({
    certificateRepository,
    blockchainService,
    auditService,
    config,
  });
  return { service, certificateRepository, blockchainService, auditService };
}

function hashOf(certificate) {
  return calculateCertificateHash({
    certificateUid: certificate.certificate_uid,
    studentUid: certificate.student_uid,
    studentName: certificate.student_name,
    title: certificate.title,
    course: certificate.course,
    department: certificate.department,
    batch: certificate.batch,
    issueDate: certificate.issue_date,
  });
}

const request = { ip: '127.0.0.1', headers: { 'user-agent': 'jest' }, user: null };

describe('VerificationService', () => {
  describe('verifyByUid', () => {
    test('returns VALID and marks an issued certificate as verified', async () => {
      const certificate = buildCertificate();
      const { service, certificateRepository } = buildService({
        certificate,
        onChainHash: hashOf(certificate),
      });

      const result = await service.verifyByUid('CERT-2026-000001', request);

      expect(result.valid).toBe(true);
      expect(result.status).toBe('VALID');
      expect(result.certificate).toMatchObject({
        uid: 'CERT-2026-000001',
        certificateUid: 'CERT-2026-000001',
        title: certificate.title,
        certificateTitle: certificate.title,
        issuedAt: certificate.issue_date,
        issueDate: certificate.issue_date,
        transactionHash: certificate.transaction_hash,
      });
      expect(certificateRepository.update).toHaveBeenCalledWith(certificate.id, {
        status: 'verified',
      });
    });

    test('returns NOT_FOUND when no certificate matches', async () => {
      const { service } = buildService({ certificate: null });
      const result = await service.verifyByUid('CERT-2026-000001', request);
      expect(result.valid).toBe(false);
      expect(result.status).toBe('NOT_FOUND');
      expect(result.certificate).toBeNull();
    });

    test('returns INVALID for a revoked certificate', async () => {
      const certificate = buildCertificate({ status: 'revoked' });
      const { service } = buildService({ certificate, onChainHash: hashOf(certificate) });
      const result = await service.verifyByUid('CERT-2026-000001', request);
      expect(result.status).toBe('INVALID');
      expect(result.valid).toBe(false);
    });

    test('returns INVALID for a pending certificate with no on-chain record', async () => {
      const certificate = buildCertificate({ status: 'pending', transaction_hash: null });
      const { service } = buildService({ certificate });
      const result = await service.verifyByUid('CERT-2026-000001', request);
      expect(result.status).toBe('INVALID');
      expect(result.valid).toBe(false);
    });

    test('returns TAMPERED when the on-chain hash does not match the stored hash', async () => {
      const certificate = buildCertificate();
      const { service } = buildService({ certificate, onChainHash: '0x' + 'b'.repeat(64) });
      const result = await service.verifyByUid('CERT-2026-000001', request);
      expect(result.status).toBe('TAMPERED');
      expect(result.valid).toBe(false);
    });

    test('returns TAMPERED when the stored hash no longer matches the canonical hash', async () => {
      const originalHash = hashOf(buildCertificate());
      const certificate = buildCertificate({
        title: 'Tampered Title', // stored title differs from what was hashed on-chain
        certificate_hash: originalHash,
      });
      const { service } = buildService({ certificate, onChainHash: originalHash });
      const result = await service.verifyByUid('CERT-2026-000001', request);
      expect(result.status).toBe('TAMPERED');
      expect(result.valid).toBe(false);
    });

    test('returns BLOCKCHAIN_MISMATCH when the on-chain record is missing or RPC fails', async () => {
      const certificate = buildCertificate();
      const { service } = buildService({
        certificate,
        onChainHash: hashOf(certificate),
        blockchainThrows: true,
      });
      const result = await service.verifyByUid('CERT-2026-000001', request);
      expect(result.status).toBe('BLOCKCHAIN_MISMATCH');
      expect(result.valid).toBe(false);
    });

    test('accepts on-chain hash with or without a 0x prefix', async () => {
      const certificate = buildCertificate();
      const hash = hashOf(certificate);
      for (const onChainHash of [hash, `0x${hash}`]) {
        const { service } = buildService({ certificate, onChainHash });
        const result = await service.verifyByUid('CERT-2026-000001', request);
        expect(result.status).toBe('VALID');
      }
    });

    test('throws a bad-request ApiError for a malformed UID', async () => {
      const { service } = buildService({ certificate: null });
      await expect(service.verifyByUid('not-a-uid', request)).rejects.toMatchObject({
        statusCode: 400,
        code: 'INVALID_UID',
      });
    });
  });

  describe('verifyByQr', () => {
    test('extracts the UID from a full verification URL', async () => {
      const certificate = buildCertificate();
      const { service } = buildService({ certificate, onChainHash: hashOf(certificate) });
      const result = await service.verifyByQr(
        `https://verify.certosec.com/?uid=CERT-2026-000001`,
        request,
      );
      expect(result.status).toBe('VALID');
    });

    test('accepts a bare UID payload', async () => {
      const certificate = buildCertificate();
      const { service } = buildService({ certificate, onChainHash: hashOf(certificate) });
      const result = await service.verifyByQr('CERT-2026-000001', request);
      expect(result.status).toBe('VALID');
    });

    test('throws INVALID_QR when the payload is not a URL or UID', async () => {
      const { service } = buildService({ certificate: null });
      await expect(service.verifyByQr('garbage-payload', request)).rejects.toMatchObject({
        statusCode: 400,
        code: 'INVALID_QR',
      });
    });
  });

  describe('verifyByTransactionHash', () => {
    test('returns TRANSACTION_NOT_FOUND when no certificate matches the hash', async () => {
      const { service } = buildService({ certificate: null });
      const result = await service.verifyByTransactionHash(`0x${'a'.repeat(64)}`, request);
      expect(result.status).toBe('TRANSACTION_NOT_FOUND');
      expect(result.valid).toBe(false);
    });

    test('returns TRANSACTION_NOT_FOUND when the tx does not exist on-chain', async () => {
      const certificate = buildCertificate();
      const { service } = buildService({ certificate, tx: null });
      const result = await service.verifyByTransactionHash(certificate.transaction_hash, request);
      expect(result.status).toBe('TRANSACTION_NOT_FOUND');
    });

    test('returns INVALID_TRANSACTION when the tx does not reference our contract', async () => {
      const certificate = buildCertificate();
      const { service } = buildService({
        certificate,
        tx: { to: '0x9999999999999999999999999999999999999999', from: '0x0000000000000000000000000000000000000001' },
      });
      const result = await service.verifyByTransactionHash(certificate.transaction_hash, request);
      expect(result.status).toBe('INVALID_TRANSACTION');
    });

    test('returns VALID when the tx references our contract and hashes match', async () => {
      const certificate = buildCertificate();
      const { service } = buildService({
        certificate,
        onChainHash: hashOf(certificate),
        tx: { to: CONTRACT_ADDRESS, from: '0x0000000000000000000000000000000000000002' },
      });
      const result = await service.verifyByTransactionHash(certificate.transaction_hash, request);
      expect(result.status).toBe('VALID');
      expect(result.valid).toBe(true);
    });
  });

  describe('audit', () => {
    test('logs successful verifications through the audit service', async () => {
      const certificate = buildCertificate();
      const { service, auditService } = buildService({
        certificate,
        onChainHash: hashOf(certificate),
      });
      await service.verifyByUid('CERT-2026-000001', request);
      expect(auditService.logRequest).toHaveBeenCalledWith(
        request,
        expect.objectContaining({ action: 'CERTIFICATE_VERIFIED' }),
      );
    });
  });
});
