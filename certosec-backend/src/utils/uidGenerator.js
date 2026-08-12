/**
 * Generates the public certificate UID: CERT-<YYYY>-<NNNNNN>.
 *
 * The sequence is derived from the largest existing UID for the current year
 * and bumped by one. The unique constraint on `certificate_uid` is the final
 * guarantee against collisions; callers retry on a unique-violation.
 */
function generateCertificateUid(year = new Date().getFullYear()) {
  return `CERT-${year}-000001`;
}

function nextSequence(existingUid, year) {
  const prefix = `CERT-${year}-`;
  let max = 0;
  if (existingUid && existingUid.startsWith(prefix)) {
    max = parseInt(existingUid.slice(prefix.length), 10) || 0;
  }
  return max + 1;
}

function buildUid(year, sequence) {
  return `CERT-${year}-${String(sequence).padStart(6, '0')}`;
}

module.exports = { generateCertificateUid, nextSequence, buildUid };
