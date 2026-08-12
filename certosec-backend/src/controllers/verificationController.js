const asyncHandler = require('../utils/asyncHandler');
const { ok } = require('../utils/responses');
const { verificationService } = require('../services/index');

const verifyUid = asyncHandler(async (req, res) => {
  ok(res, await verificationService.verifyByUid(req.body.uid, req));
});

const verifyQr = asyncHandler(async (req, res) => {
  ok(res, await verificationService.verifyByQr(req.body.payload, req));
});

const verifyTransaction = asyncHandler(async (req, res) => {
  ok(res, await verificationService.verifyByTransactionHash(req.body.txHash, req));
});

/** GET alias for the Flutter client: /verify?uid=... or /verify?txHash=... */
const verifyByQuery = asyncHandler(async (req, res) => {
  const { uid, txHash } = req.query;
  if (txHash) {
    return ok(res, await verificationService.verifyByTransactionHash(txHash, req));
  }
  return ok(res, await verificationService.verifyByUid(uid, req));
});

module.exports = { verifyUid, verifyQr, verifyTransaction, verifyByQuery };
