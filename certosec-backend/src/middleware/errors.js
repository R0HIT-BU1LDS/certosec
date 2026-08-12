const ApiError = require('../utils/ApiError');
const logger = require('../utils/logger');
const env = require('../config/env');

/** 404 for unknown routes. */
function notFound(req, res, next) {
  next(
    new ApiError(
      404,
      'NOT_FOUND',
      `Route ${req.method} ${req.originalUrl} was not found.`,
    ),
  );
}

/**
 * Centralized error handler. Never leaks stack traces or internal details in
 * production. Maps known error types (ApiError, multer, validation) and masks
 * everything else as a generic 500.
 */
function errorHandler(err, req, res, next) {
  // Multer-specific failures.
  if (err && err.name === 'MulterError') {
    let message = 'Unexpected file upload error.';
    if (err.code === 'LIMIT_FILE_SIZE') {
      message = `The PDF exceeds the ${Math.round(env.storage.maxPdfBytes / 1024 / 1024)}MB limit.`;
    } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      message = 'Unexpected file field. Expected a single "pdf" file.';
    }
    return res.status(400).json({
      success: false,
      error: { code: 'UPLOAD_ERROR', message },
    });
  }

  const status = err.statusCode && Number.isInteger(err.statusCode) ? err.statusCode : 500;
  const isOperational = Boolean(err.isOperational);

  if (status >= 500) {
    logger.error('Request error', {
      method: req.method,
      path: req.originalUrl,
      message: err.message,
      stack: err.stack,
    });
  }

  let code = err.code || 'INTERNAL_ERROR';
  let message = err.message || 'The server encountered an error.';

  if (!isOperational && status >= 500) {
    code = 'INTERNAL_ERROR';
    message = 'The server encountered an error. Please try again later.';
  }

  const body = { success: false, error: { code, message } };
  if (err.errors) {
    body.errors = err.errors;
  }
  return res.status(status).json(body);
}

module.exports = { notFound, errorHandler };
