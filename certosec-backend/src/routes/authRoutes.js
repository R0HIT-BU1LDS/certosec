const router = require('express').Router();
const authValidators = require('../validators/authValidators');
const authController = require('../controllers/authController');
const { loginLimiter } = require('../middleware/rateLimiters');
const { requireAuth } = require('../middleware/authenticate');

router.post('/login', loginLimiter, authValidators.login, authController.login);
router.post('/forgot-password', loginLimiter, authValidators.forgotPassword, authController.forgotPassword);
router.get('/me', requireAuth, authController.me);
router.post('/logout', requireAuth, authController.logout);

module.exports = router;
