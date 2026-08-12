const crypto = require('crypto');

/**
 * CANONICAL CERTIFICATE HASH FORMAT (v1) — THE single source of truth.
 *
 * The hash is computed over the certificate's immutable identity fields only.
 * Mutable database metadata (status, timestamps, storage paths, transaction
 * ids) is NEVER hashed. If any hashed field is edited after issuance the
 * certificate fails verification (TAMPERED).
 *
 * Serialization: a JSON object with a fixed key order:
 *   {
 *     "version": 1,
 *     "certificateUid": "CERT-2026-000001",
 *     "studentUid":     "STU-2026-001",
 *     "studentName":    "Ada Lovelace",
 *     "title":          "Bachelor of Science in Computer Science",
 *     "course":         "B.Sc. Computer Science",
 *     "department":     "Computer Science",
 *     "batch":          "2026",
 *     "issueDate":      "2026-08-12"     // UTC date, YYYY-MM-DD
 *   }
 *
 * All string values are trimmed; null/undefined become "". The JSON is
 * written with no extra whitespace, so the byte stream is deterministic.
 */
const CANONICAL_FORMAT_VERSION = 1;

function normalize(value) {
  return value === null || value === undefined ? '' : String(value).trim();
}

/** Accepts a Date, ISO string, or 'YYYY-MM-DD'; returns 'YYYY-MM-DD' (UTC). */
function isoDate(value) {
  if (value === null || value === undefined || value === '') return '';
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  const str = String(value);
  if (/^\d{4}-\d{2}-\d{2}/.test(str)) return str.slice(0, 10);
  const parsed = new Date(str);
  return Number.isNaN(parsed.getTime()) ? '' : parsed.toISOString().slice(0, 10);
}

function createCanonicalCertificateData(data) {
  return JSON.stringify({
    version: CANONICAL_FORMAT_VERSION,
    certificateUid: normalize(data.certificateUid),
    studentUid: normalize(data.studentUid),
    studentName: normalize(data.studentName),
    title: normalize(data.title),
    course: normalize(data.course),
    department: normalize(data.department),
    batch: normalize(data.batch),
    issueDate: isoDate(data.issueDate),
  });
}

/** SHA-256 of the canonical serialization, lowercase hex (64 chars). */
function calculateCertificateHash(data) {
  return crypto
    .createHash('sha256')
    .update(createCanonicalCertificateData(data), 'utf8')
    .digest('hex');
}

module.exports = {
  CANONICAL_FORMAT_VERSION,
  createCanonicalCertificateData,
  calculateCertificateHash,
};
