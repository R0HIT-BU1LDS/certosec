const { body, param, query } = require('express-validator');
const { validate, paginationRules, UUID_PATTERN, UID_PATTERN } = require('./common');

const studentIdRule = body('studentId')
  .trim()
  .matches(UUID_PATTERN)
  .withMessage('studentId must be the student record UUID.');

const titleRule = body('title')
  .trim()
  .notEmpty()
  .withMessage('Certificate title is required.')
  .isLength({ max: 200 })
  .withMessage('Title must be 200 characters or fewer.');

const descriptionRule = body('description')
  .optional({ values: 'falsy' })
  .isLength({ max: 2000 })
  .withMessage('Description must be 2000 characters or fewer.');

const issueBody = [studentIdRule, titleRule, descriptionRule];

const identifierParam = param('id')
  .trim()
  .custom((value) => UUID_PATTERN.test(value) || UID_PATTERN.test(value))
  .withMessage('Certificate id must be a UUID or a CERT-YYYY-NNNNNN UID.');

const listQuery = validate([
  ...paginationRules,
  query('status')
    .optional()
    .trim()
    .isIn(['pending', 'issued', 'verified', 'revoked'])
    .withMessage('status must be one of: pending, issued, verified, revoked.'),
]);

const create = validate([...issueBody]);
const issue = validate([...issueBody]);
const get = validate([identifierParam]);
const download = validate([identifierParam]);

module.exports = { listQuery, create, issue, get, download };
