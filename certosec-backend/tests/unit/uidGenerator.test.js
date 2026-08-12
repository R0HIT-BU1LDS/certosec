const {
  generateCertificateUid,
  nextSequence,
  buildUid,
} = require('../../src/utils/uidGenerator');

describe('uidGenerator', () => {
  test('generateCertificateUid starts a year at 000001', () => {
    expect(generateCertificateUid(2026)).toBe('CERT-2026-000001');
  });

  test('defaults the year to the current year', () => {
    expect(generateCertificateUid()).toBe(`CERT-${new Date().getFullYear()}-000001`);
  });

  test('nextSequence bumps the sequence of a same-year UID', () => {
    expect(nextSequence('CERT-2026-000042', 2026)).toBe(43);
  });

  test('nextSequence treats a different year as a fresh sequence', () => {
    expect(nextSequence('CERT-2025-000100', 2026)).toBe(1);
  });

  test('nextSequence handles null / malformed UIDs', () => {
    expect(nextSequence(null, 2026)).toBe(1);
    expect(nextSequence('garbage', 2026)).toBe(1);
    expect(nextSequence('CERT-2026-ABC', 2026)).toBe(1);
  });

  test('buildUid zero-pads the sequence to six digits', () => {
    expect(buildUid(2026, 1)).toBe('CERT-2026-000001');
    expect(buildUid(2026, 999999)).toBe('CERT-2026-999999');
  });
});
