const ApiError = require('../utils/ApiError');
const { calculateCertificateHash } = require('./hashService');
const logger = require('../utils/logger');

/**
 * VerificationService — the ONE central verification engine.
 *
 * All three public entry points (QR / UID / transaction hash) funnel into
 * `verifyCertificate`. A verdict is ALWAYS returned as a result object; only
 * malformed input surfaces as an HTTP validation error. A missing/tampered
 * certificate is a verdict, not a 404.
 *
 * Checks performed (spec):
 *   1. Does the certificate exist?               -> NOT_FOUND
 *   2. Does the blockchain record exist?         -> BLOCKCHAIN_MISMATCH
 *   3. Does the record belong to our contract?   -> (tx-hash path only) INVALID_TRANSACTION
 *   4. Does the certificate UID match?           -> handled by on-chain lookup by UID
 *   5. Does the certificate hash match?          -> TAMPERED
 *   6. Is the certificate status valid?          -> INVALID when revoked/pending
 */
class VerificationService {
  constructor({ certificateRepository, blockchainService, auditService, config }) {
    this.certificateRepository = certificateRepository;
    this.blockchainService = blockchainService;
    this.auditService = auditService;
    this.config = config;
  }

  async verifyByQr(payload, request) {
    const uid = this.extractUidFromQr(payload);
    if (!uid) {
      throw ApiError.badRequest(
        'INVALID_QR',
        'The QR code did not contain a valid certificate UID.',
      );
    }
    return this.verifyCertificate({ uid }, request);
  }

  async verifyByUid(uid, request) {
    return this.verifyCertificate({ uid }, request);
  }

  async verifyByTransactionHash(transactionHash, request) {
    return this.verifyCertificate({ transactionHash }, request);
  }

  /** Parses a scanned payload: full verification URL or a bare UID. */
  extractUidFromQr(payload) {
    const raw = String(payload || '').trim();
    if (!raw) return null;
    try {
      const uri = new URL(raw);
      const uid = uri.searchParams.get('uid');
      if (uid) return uid.trim().toUpperCase();
    } catch {
      // Not a URL — fall through to raw UID matching.
    }
    const match = /^(CERT-\d{4}-\d{6})$/i.exec(raw);
    return match ? match[1].toUpperCase() : null;
  }

  async verifyCertificate({ uid, transactionHash }, request) {
    let certificate;

    if (transactionHash) {
      certificate = await this.certificateRepository.findByTransactionHash(transactionHash);
      if (!certificate) {
        return this._verdict('TRANSACTION_NOT_FOUND', 'No certificate matches this transaction hash.', false);
      }
    } else {
      if (!uid || !/^CERT-\d{4}-\d{6}$/i.test(uid)) {
        throw ApiError.badRequest('INVALID_UID', 'The certificate UID is not valid.');
      }
      certificate = await this.certificateRepository.findByUid(uid.toUpperCase());
      if (!certificate) {
        return this._verdict('NOT_FOUND', 'No certificate was found with that UID.', false);
      }
    }

    // Check 6: status gate.
    if (certificate.status === 'revoked') {
      return this._verdict('INVALID', 'This certificate has been revoked.', false);
    }
    if (certificate.status === 'pending' || !certificate.transaction_hash) {
      return this._verdict('INVALID', 'This certificate has not been issued on the blockchain yet.', false);
    }

    // Transaction-hash path: confirm the tx exists and references our contract.
    if (transactionHash) {
      let tx = null;
      try {
        tx = await this.blockchainService.getTransaction(transactionHash);
      } catch (err) {
        logger.warn('Transaction lookup failed', { hash: transactionHash, message: err.message });
      }
      if (!tx) {
        return this._verdict('TRANSACTION_NOT_FOUND', 'The transaction was not found on the network.', false);
      }
      const contractAddress = (this.config.blockchain.contractAddress || '').toLowerCase();
      const txTo = tx.to ? String(tx.to).toLowerCase() : null;
      if (!txTo || (contractAddress && txTo !== contractAddress)) {
        return this._verdict('INVALID_TRANSACTION', 'The transaction does not reference the CertoSec contract.', false);
      }
    }

    // Checks 2-5: on-chain record vs stored hash vs recomputed canonical hash.
    let onChain = null;
    try {
      onChain = await this.blockchainService.getCertificate(certificate.certificate_uid);
    } catch (err) {
      logger.warn('On-chain lookup failed', { uid: certificate.certificate_uid, message: err.message });
    }
    if (!onChain || !onChain.exists) {
      return this._verdict('BLOCKCHAIN_MISMATCH', 'The certificate is not recorded on the blockchain.', false);
    }

    if (normalizeHash(onChain.hash) !== certificate.certificate_hash) {
      return this._verdict('TAMPERED', 'The on-chain record does not match the stored certificate.', false);
    }

    const recomputed = calculateCertificateHash({
      certificateUid: certificate.certificate_uid,
      studentUid: certificate.student_uid,
      studentName: certificate.student_name,
      title: certificate.title,
      course: certificate.course,
      department: certificate.department,
      batch: certificate.batch,
      issueDate: certificate.issue_date,
    });
    if (recomputed !== certificate.certificate_hash) {
      return this._verdict('TAMPERED', 'The certificate data has been altered since issuance.', false);
    }

    // Everything checks out.
    if (certificate.status === 'issued') {
      await this.certificateRepository
        .update(certificate.id, { status: 'verified' })
        .catch((err) => logger.warn('Could not mark certificate verified', { id: certificate.id, message: err.message }));
      certificate.status = 'verified';
    }

    await this.auditService.logRequest(request, {
      action: 'CERTIFICATE_VERIFIED',
      entityType: 'certificate',
      entityId: certificate.id,
      metadata: { uid: certificate.certificate_uid, method: transactionHash ? 'transaction' : 'uid' },
    });

    return this._verdict('VALID', 'This certificate is authentic.', true, certificate);
  }

  _verdict(status, message, valid, certificate = null) {
    return {
      valid,
      status,
      message,
      verifiedAt: new Date().toISOString(),
      certificate: certificate
        ? {
            uid: certificate.certificate_uid,
            certificateUid: certificate.certificate_uid,
            studentName: certificate.student_name,
            title: certificate.title,
            certificateTitle: certificate.title,
            course: certificate.course,
            department: certificate.department,
            batch: certificate.batch,
            issuedAt: certificate.issue_date,
            issueDate: certificate.issue_date,
            transactionHash: certificate.transaction_hash,
            issuerAddress: certificate.issuer_address,
            blockNumber: certificate.block_number != null ? Number(certificate.block_number) : null,
            network: certificate.network || this.config.blockchain.networkName,
          }
        : null,
    };
  }
}

function normalizeHash(value) {
  if (typeof value === 'string') {
    return value.replace(/^0x/, '').toLowerCase();
  }
  if (typeof value === 'object' && value !== null && value.toString) {
    return normalizeHash(value.toString());
  }
  return String(value || '').replace(/^0x/, '').toLowerCase();
}

module.exports = VerificationService;
