const ApiError = require('./ApiError');

const UNIQUE_VIOLATION = '23505';
const FOREIGN_KEY_VIOLATION = '23503';
const CHECK_VIOLATION = '23514';

function isUniqueViolation(error) {
  return error && error.code === UNIQUE_VIOLATION;
}

function isForeignKeyViolation(error) {
  return error && error.code === FOREIGN_KEY_VIOLATION;
}

/**
 * Converts a PostgrestError into a user-safe ApiError. Returns a generic 500
 * for anything unexpected (full detail is logged by the caller, never sent).
 * The raw error is attached as `original` so callers can inspect the
 * Postgres error code (e.g. unique-violation retry logic).
 */
function toApiError(error, context = 'database operation') {
  let apiError;
  if (isUniqueViolation(error)) {
    apiError = ApiError.conflict(
      'DUPLICATE_ENTRY',
      'A record with that value already exists.',
    );
  } else if (isForeignKeyViolation(error)) {
    apiError = ApiError.badRequest(
      'INVALID_REFERENCE',
      'The referenced record does not exist.',
    );
  } else if (error && error.code === CHECK_VIOLATION) {
    apiError = ApiError.badRequest(
      'INVALID_VALUE',
      'One of the values is not allowed for its field.',
    );
  } else if (error && error.message && /storage/i.test(error.message)) {
    apiError = new ApiError(502, 'STORAGE_ERROR', 'File storage operation failed.');
  } else {
    apiError = new ApiError(500, 'DATABASE_ERROR', 'The operation could not be completed.');
  }
  if (error) apiError.original = error;
  return apiError;
}

/** Escapes LIKE wildcards so user search terms are treated literally. */
function escapeLike(term) {
  return term.replace(/[\\%_]/g, (ch) => `\\${ch}`);
}

module.exports = { isUniqueViolation, isForeignKeyViolation, toApiError, escapeLike };
