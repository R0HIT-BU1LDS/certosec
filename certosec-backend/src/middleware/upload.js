const multer = require('multer');
const env = require('../config/env');
const ApiError = require('../utils/ApiError');

/**
 * PDF upload handling. Files are kept in memory, size-capped, restricted to
 * PDFs, and given server-generated names later in StorageService. The client's
 * original filename is never used to build a storage path.
 */
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: env.storage.maxPdfBytes,
    files: 1,
  },
  fileFilter: (req, file, cb) => {
    const isPdfMime = file.mimetype === 'application/pdf';
    const isPdfExtension = /\.pdf$/i.test(file.originalname || '');
    if (isPdfMime || isPdfExtension) {
      return cb(null, true);
    }
    return cb(
      new ApiError(400, 'INVALID_PDF', 'Only PDF files can be uploaded as certificates.'),
    );
  },
});

module.exports = { uploadSinglePdf: upload.single('pdf') };
