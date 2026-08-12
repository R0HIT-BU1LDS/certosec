const { validationResult } = require('express-validator');
const ApiError = require('../utils/ApiError');

const UID_PATTERN = /^CERT-\d{4}-\d{6}$/i;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const TX_HASH_PATTERN = /^0x[0-9a-f]{64}$/i;

/**
 * Wraps an express-validator rule chain with the error-mapping middleware that
 * converts validation failures into the documented `{ success, error,
 * errors: { field: message } }` response (422).
 */
function validate(rules) {
  return [
    ...rules,
    (req, res, next) => {
      const result = validationResult(req);
      if (result.isEmpty()) return next();

      const errors = {};
      for (const item of result.array()) {
        const field = item.path || item.param || 'body';
        if (!errors[field]) errors[field] = item.msg;
      }
      return next(
        ApiError.validation('Please correct the highlighted fields.', errors),
      );
    },
  ];
}

/** Common pagination query rules (shared by list endpoints). */
const paginationRules = [
  require('express-validator').query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('page must be a positive integer.')
    .toInt(),
  require('express-validator').query('pageSize')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('pageSize must be an integer between 1 and 100.')
    .toInt(),
  require('express-validator').query('search')
    .optional()
    .trim()
    .isLength({ max: 120 })
    .withMessage('search must be 120 characters or fewer.'),
];

module.exports = {
  validate,
  paginationRules,
  UID_PATTERN,
  UUID_PATTERN,
  TX_HASH_PATTERN,
};
