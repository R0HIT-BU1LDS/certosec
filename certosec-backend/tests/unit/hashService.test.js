const {
  CANONICAL_FORMAT_VERSION,
  createCanonicalCertificateData,
  calculateCertificateHash,
} = require('../../src/services/hashService');

const BASE = {
  certificateUid: 'CERT-2026-000001',
  studentUid: 'STU-2026-001',
  studentName: 'Ada Lovelace',
  title: 'Bachelor of Science in Computer Science',
  course: 'B.Sc. Computer Science',
  department: 'Computer Science',
  batch: '2026',
  issueDate: '2026-08-12',
};

describe('hashService — canonical certificate hash', () => {
  test('produces a deterministic lowercase 64-char SHA-256 hex hash', () => {
    const hash = calculateCertificateHash(BASE);
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
    expect(calculateCertificateHash(BASE)).toBe(hash);
  });

  test('result is stable regardless of input key order', () => {
    const shuffled = {
      batch: BASE.batch,
      title: BASE.title,
      issueDate: BASE.issueDate,
      studentName: BASE.studentName,
      course: BASE.course,
      department: BASE.department,
      certificateUid: BASE.certificateUid,
      studentUid: BASE.studentUid,
    };
    expect(calculateCertificateHash(shuffled)).toBe(calculateCertificateHash(BASE));
  });

  test('changing any hashed field changes the hash', () => {
    const withDifferentTitle = { ...BASE, title: 'Bachelor of Science in Mathematics' };
    const withDifferentName = { ...BASE, studentName: 'Grace Hopper' };
    expect(calculateCertificateHash(withDifferentTitle)).not.toBe(calculateCertificateHash(BASE));
    expect(calculateCertificateHash(withDifferentName)).not.toBe(calculateCertificateHash(BASE));
  });

  test('null / undefined values serialize as empty strings', () => {
    const sparse = {
      certificateUid: 'CERT-2026-000002',
      studentUid: null,
      studentName: undefined,
      title: '',
      course: '  ',
      department: null,
      batch: undefined,
      issueDate: '',
    };
    const canonical = createCanonicalCertificateData(sparse);
    const parsed = JSON.parse(canonical);
    expect(parsed.version).toBe(CANONICAL_FORMAT_VERSION);
    expect(parsed.studentUid).toBe('');
    expect(parsed.studentName).toBe('');
    expect(parsed.course).toBe('');
  });

  test('values are trimmed of surrounding whitespace', () => {
    const messy = { ...BASE, studentName: `  ${BASE.studentName}  `, title: `  ${BASE.title}  ` };
    expect(calculateCertificateHash(messy)).toBe(calculateCertificateHash(BASE));
  });

  test('issueDate is normalized to YYYY-MM-DD (UTC) regardless of input format', () => {
    const iso = { ...BASE, issueDate: '2026-08-12T23:59:59.999Z' };
    const date = { ...BASE, issueDate: new Date('2026-08-12T10:00:00.000Z') };
    expect(calculateCertificateHash(iso)).toBe(calculateCertificateHash(BASE));
    expect(calculateCertificateHash(date)).toBe(calculateCertificateHash(BASE));
  });

  test('serialization uses fixed key order and no whitespace', () => {
    const canonical = createCanonicalCertificateData(BASE);
    expect(canonical).toContain('"version":1');
    expect(canonical).not.toContain('\n');
    expect(JSON.parse(canonical)).toEqual({
      version: 1,
      certificateUid: 'CERT-2026-000001',
      studentUid: 'STU-2026-001',
      studentName: 'Ada Lovelace',
      title: 'Bachelor of Science in Computer Science',
      course: 'B.Sc. Computer Science',
      department: 'Computer Science',
      batch: '2026',
      issueDate: '2026-08-12',
    });
  });
});
