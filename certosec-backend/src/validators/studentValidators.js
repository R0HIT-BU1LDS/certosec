const { body, param } = require('express-validator');
const { validate, paginationRules, UUID_PATTERN } = require('./common');

const studentIdRule = body('studentId')
  .trim()
  .notEmpty()
  .withMessage('Student ID is required.')
  .isLength({ max: 40 })
  .withMessage('Student ID must be 40 characters or fewer.');

const nameRule = body('name')
  .trim()
  .notEmpty()
  .withMessage('Name is required.')
  .isLength({ max: 200 })
  .withMessage('Name must be 200 characters or fewer.');

const emailRule = body('email')
  .optional({ values: 'falsy' })
  .isEmail()
  .withMessage('Enter a valid email address.')
  .normalizeEmail();

const requiredField = (field) =>
  body(field)
    .trim()
    .notEmpty()
    .withMessage('This field is required.')
    .isLength({ max: 200 })
    .withMessage('This field must be 200 characters or fewer.');

const optionalUrl = (field) =>
  body(field)
    .optional({ values: 'falsy' })
    .isURL({ protocols: ['https', 'http'], require_protocol: true })
    .withMessage('Enter a valid URL.');

const idParam = param('id')
  .matches(UUID_PATTERN)
  .withMessage('Student id must be a valid UUID.');

const studentBody = [
  studentIdRule,
  nameRule,
  emailRule,
  requiredField('department'),
  requiredField('batch'),
  requiredField('course'),
  body('phone').optional({ values: 'falsy' }).isLength({ max: 30 }).withMessage('Phone must be 30 characters or fewer.'),
  optionalUrl('profilePhotoUrl'),
];

const listQuery = validate([
  ...paginationRules,
  require('express-validator').query('department')
    .optional()
    .trim()
    .isLength({ max: 120 })
    .withMessage('department must be 120 characters or fewer.'),
]);

const create = validate([...studentBody]);
const update = validate([...studentBody, idParam]);
const get = validate([idParam]);
const remove = validate([idParam]);

module.exports = { listQuery, create, update, get, remove };
