const { body, param } = require('express-validator');
const { validate, UUID_PATTERN } = require('./common');

const login = validate([
  body('email').isEmail().withMessage('Enter a valid email address.').normalizeEmail(),
  body('password').isString().notEmpty().withMessage('Password is required.'),
]);

const forgotPassword = validate([
  body('email').isEmail().withMessage('Enter a valid email address.').normalizeEmail(),
]);

const me = validate([]);

module.exports = { login, forgotPassword, me };
