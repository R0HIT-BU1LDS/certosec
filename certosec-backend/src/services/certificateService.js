const ApiError = require('../utils/ApiError');
const { toCertificateJson } = require('../models/certificate');
const { calculateCertificateHash } = require('./hashService');
const { nextSequence, buildUid } = require('../utils/uidGenerator');
const { isUniqueViolation } = require('../utils/db');
const logger = require('../utils/logger');

const MAX_UID_RETRIES = 3;

/**
 * CertificateService orchestrates certificate management and the blockchain
 * issuance pipeline:
 *
 *   validate student -> generate UID -> canonical hash -> (optional) store
 *   PDF -> insert pending row -> submit to chain -> wait for confirmation ->
 *   persist proof -> mark issued.
 *
 * A blockchain failure leaves a `pending` certificate behind so the record
 * (and its hash) is never lost.
 */
class CertificateService {
  constructor({ certificateRepository, studentRepository, storageService, blockchainService, auditService, config }) {
    this.certificateRepository = certificateRepository;
    this.studentRepository = studentRepository;
    this.storageService = storageService;
    this.blockchainService = blockchainService;
    this.auditService = auditService;
    this.config = config;
  }

  async list({ page, pageSize, search, status }) {
    const result = await this.certificateRepository.paginate({
      page,
      pageSize,
      search,
      status,
    });
    return {
      items: result.items.map(toCertificateJson),
      total: result.total,
      page,
      pageSize,
      totalPages: result.total === 0 ? 0 : Math.ceil(result.total / pageSize),
    };
  }

  /** Fetches a certificate by its public UID or internal UUID. */
  async get(identifier) {
    const row = await this.find(identifier);
    if (!row) {
      throw ApiError.notFound('CERTIFICATE_NOT_FOUND', 'Certificate not found.');
    }
    return toCertificateJson(row);
  }

  /**
   * Full issuance (POST /certificates/issue): record + optional PDF + on-chain
   * proof + status `issued`.
   */
  async issue(payload, request, file) {
    return this._persistAndProve(payload, request, file, { full: true });
  }

  /**
   * Record-only creation (POST /certificates): stores the certificate and
   * hash with status `pending`, without touching the blockchain. This mirrors
   * the spec's "store initial certificate record" step.
   */
  async createPending(payload, request, file) {
    return this._persistAndProve(payload, request, file, { full: false });
  }

  /** Produces a signed download URL for the stored PDF. */
  async getDownloadUrl(identifier, request) {
    const row = await this.find(identifier);
    if (!row) {
      throw ApiError.notFound('CERTIFICATE_NOT_FOUND', 'Certificate not found.');
    }
    if (!row.pdf_path) {
      throw ApiError.notFound(
        'CERTIFICATE_PDF_NOT_FOUND',
        'No stored certificate PDF is available for this certificate.',
      );
    }
    const url = await this.storageService.createSignedUrl(row.pdf_path);

    await this.auditService.logRequest(request, {
      action: 'CERTIFICATE_DOWNLOAD',
      entityType: 'certificate',
      entityId: row.id,
    });

    return {
      uid: row.certificate_uid,
      url,
      expiresIn: this.config.storage.signedUrlExpiry,
    };
  }

  async _persistAndProve(payload, request, file, { full }) {
    this.storageService.validatePdfFile(file);

    const student = await this.studentRepository.findById(payload.studentId);
    if (!student) {
      throw ApiError.badRequest('STUDENT_NOT_FOUND', 'The selected student does not exist.');
    }

    const issueDate = new Date().toISOString().slice(0, 10);
    const issuerName = request.user.institutionName || this.config.issuer.name;

    // --- Generate UID + canonical hash (server-controlled, never trusted
    // --- from the client).
    let row = null;
    for (let attempt = 0; attempt < MAX_UID_RETRIES; attempt += 1) {
      const uid = await this._nextUid();
      const certificateHash = calculateCertificateHash({
        certificateUid: uid,
        studentUid: student.student_uid,
        studentName: student.full_name,
        title: payload.title,
        course: student.course,
        department: student.department,
        batch: student.batch,
        issueDate,
      });

      try {
        row = await this.certificateRepository.create({
          certificate_uid: uid,
          student_id: student.id,
          student_uid: student.student_uid,
          student_name: student.full_name,
          title: payload.title,
          description: payload.description || null,
          course: student.course,
          department: student.department,
          batch: student.batch,
          issue_date: issueDate,
          certificate_hash: certificateHash,
          issuer_name: issuerName,
          status: 'pending',
          created_by: request.user.id,
        });
        break;
      } catch (err) {
        if (attempt < MAX_UID_RETRIES - 1 && isUniqueViolation(err.original)) {
          logger.warn(`Certificate UID collision, retrying (attempt ${attempt + 2})`);
          continue;
        }
        throw err;
      }
    }
    if (!row) {
      throw new ApiError(500, 'CERTIFICATE_CREATE_FAILED', 'Could not create the certificate record.');
    }

    await this.auditService.logRequest(request, {
      action: 'CERTIFICATE_CREATED',
      entityType: 'certificate',
      entityId: row.id,
    });

    // --- Optional PDF upload.
    if (file) {
      const pdfPath = await this.storageService.uploadPdf(file.buffer, row.certificate_uid);
      row = await this.certificateRepository.update(row.id, { pdf_path: pdfPath });
    }

    if (!full) {
      return toCertificateJson(row);
    }

    // --- Blockchain proof.
    try {
      const proof = await this.blockchainService.issueCertificate({
        uid: row.certificate_uid,
        hash: row.certificate_hash,
      });
      row = await this.certificateRepository.update(row.id, {
        status: 'issued',
        transaction_hash: proof.transactionHash,
        block_number: proof.blockNumber,
        block_timestamp: proof.blockTimestamp ? new Date(proof.blockTimestamp).toISOString() : null,
        issuer_address: proof.issuerAddress,
        contract_address: proof.contractAddress,
        network: proof.network,
      });
    } catch (err) {
      logger.error('Blockchain issuance failed', {
        uid: row.certificate_uid,
        message: err.message,
      });
      await this.auditService.logRequest(request, {
        action: 'CERTIFICATE_CREATED',
        entityType: 'certificate',
        entityId: row.id,
        metadata: { blockchainError: err.message, uid: row.certificate_uid },
      });
      throw new ApiError(
        502,
        'BLOCKCHAIN_ERROR',
        'The certificate record was created but could not be written to the blockchain. It is saved as pending; retry issuance when the network is healthy.',
      );
    }

    await this.auditService.logRequest(request, {
      action: 'CERTIFICATE_ISSUED',
      entityType: 'certificate',
      entityId: row.id,
      metadata: {
        transactionHash: row.transaction_hash,
        blockNumber: Number(row.block_number),
        network: row.network,
      },
    });

    return toCertificateJson(row);
  }

  async _nextUid() {
    const year = new Date().getFullYear();
    const latest = await this.certificateRepository.latestUidForYear(year);
    const sequence = nextSequence(latest, year);
    return buildUid(year, sequence);
  }

  async find(identifier) {
    if (/^CERT-\d{4}-\d{6}$/i.test(identifier)) {
      return this.certificateRepository.findByUid(identifier);
    }
    return this.certificateRepository.findById(identifier);
  }
}

module.exports = CertificateService;
