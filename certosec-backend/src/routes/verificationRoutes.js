const router = require('express').Router();
const verificationValidators = require('../validators/verificationValidators');
const verificationController = require('../controllers/verificationController');
const { verificationLimiter } = require('../middleware/rateLimiters');

router.use(verificationLimiter);

router.post('/qr', verificationValidators.verifyQr, verificationController.verifyQr);
router.post('/uid', verificationValidators.verifyUid, verificationController.verifyUid);
router.post('/transaction', verificationValidators.verifyTransaction, verificationController.verifyTransaction);
router.get('/', verificationValidators.verifyByQuery, verificationController.verifyByQuery);

module.exports = router;
