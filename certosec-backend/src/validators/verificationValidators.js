const { body, query } = require('express-validator');
const { validate, UID_PATTERN, TX_HASH_PATTERN } = require('./common');

const uidBody = body('uid')
  .trim()
  .matches(UID_PATTERN)
  .withMessage('Certificate UID must match CERT-YYYY-NNNNNN.')
  .toUpperCase();

/** QR payloads may be a full verification URL or a bare UID. */
const qrBody = body('payload')
  .trim()
  .notEmpty()
  .withMessage('QR payload is required.')
  .custom((value) => {
    const bare = UID_PATTERN.test(value);
    if (bare) return true;
    try {
      const url = new URL(value);
      return url.searchParams.has('uid');
    } catch {
      return false;
    }
  })
  .withMessage('QR payload must be a verification URL or a certificate UID.');

const txHashBody = body('txHash')
  .trim()
  .matches(TX_HASH_PATTERN)
  .withMessage('Transaction hash must be a 0x-prefixed 64-character hex string.');

const exactlyOneLookup = (req, res, next) => {
  const uid = req.body?.uid || req.query?.uid;
  const txHash = req.body?.txHash || req.query?.txHash;
  const present = [Boolean(uid), Boolean(txHash)].filter(Boolean).length;
  if (present !== 1) {
    return res.status(422).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Provide exactly one of uid or txHash.',
      },
    });
  }
  return next();
};

const verifyUid = validate([uidBody]);
const verifyQr = validate([qrBody]);
const verifyTransaction = validate([txHashBody]);

/** GET alias: /verify?uid=... or /verify?txHash=... (frontend compatibility). */
const verifyByQuery = [
  validate([
    query('uid').optional({ values: 'falsy' }).trim().matches(UID_PATTERN).withMessage('Certificate UID must match CERT-YYYY-NNNNNN.'),
    query('txHash').optional({ values: 'falsy' }).trim().matches(TX_HASH_PATTERN).withMessage('Transaction hash must be a 0x-prefixed 64-character hex string.'),
  ]),
  exactlyOneLookup,
];

module.exports = { verifyUid, verifyQr, verifyTransaction, verifyByQuery };
