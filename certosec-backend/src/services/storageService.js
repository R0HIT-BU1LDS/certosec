const { v4: uuidv4 } = require('uuid');
const ApiError = require('../utils/ApiError');
const logger = require('../utils/logger');

/**
 * StorageService manages certificate PDFs in a PRIVATE Supabase Storage
 * bucket. Nothing here is ever publicly readable; access is via short-lived
 * signed URLs generated through the backend.
 */
class StorageService {
  constructor({ supabase, config }) {
    this.supabase = supabase;
    this.bucket = config.storage.bucket;
    this.maxBytes = config.storage.maxPdfBytes;
    this.signedUrlExpiry = config.storage.signedUrlExpiry;
  }

  /**
   * Validates a multer-uploaded PDF. Rejects empty, oversized, or non-PDF
   * files. Extension/MIME checks are secondary — the magic bytes decide.
   */
  validatePdfFile(file) {
    if (!file) return;
    if (!file.buffer || file.buffer.length === 0) {
      throw ApiError.badRequest('INVALID_PDF', 'The certificate PDF is empty.');
    }
    if (file.buffer.length > this.maxBytes) {
      throw ApiError.badRequest(
        'FILE_TOO_LARGE',
        `The PDF exceeds the ${Math.round(this.maxBytes / 1024 / 1024)}MB limit.`,
      );
    }
    const header = file.buffer.subarray(0, 5).toString('latin1');
    if (header !== '%PDF-') {
      throw ApiError.badRequest(
        'INVALID_PDF',
        'Only PDF files can be uploaded as certificates.',
      );
    }
  }

  /**
   * Uploads a PDF to `certificates/{certificateUid}/{uuid}.pdf`. The filename
   * is server-generated — the client's original filename is never used.
   */
  async uploadPdf(buffer, certificateUid) {
    const storagePath = `certificates/${certificateUid}/${uuidv4()}.pdf`;
    const { error } = await this.supabase.storage
      .from(this.bucket)
      .upload(storagePath, buffer, {
        contentType: 'application/pdf',
        upsert: false,
      });
    if (error) {
      logger.error('Storage upload failed', { path: storagePath, message: error.message });
      throw new ApiError(502, 'STORAGE_ERROR', 'Could not store the certificate PDF.');
    }
    return storagePath;
  }

  /** Short-lived signed URL for downloading a stored PDF. */
  async createSignedUrl(storagePath) {
    const { data, error } = await this.supabase.storage
      .from(this.bucket)
      .createSignedUrl(storagePath, this.signedUrlExpiry);
    if (error || !data?.signedUrl) {
      logger.error('Signed URL generation failed', { path: storagePath });
      throw new ApiError(502, 'STORAGE_ERROR', 'Could not prepare the PDF download.');
    }
    return data.signedUrl;
  }
}

module.exports = StorageService;
