/**
 * ApiError is the single application error type. Controllers and services
 * throw it with an HTTP status, a stable machine-readable `code`, and a
 * user-safe `message`. The centralized error handler maps it to the documented
 * `{ success: false, error: { code, message } }` response shape.
 */
class ApiError extends Error {
  constructor(statusCode, code, message, options = {}) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.code = code;
    // Optional per-field validation errors: { field: message }
    this.errors = options.errors || undefined;
    this.isOperational = true;
  }

  static badRequest(code, message) {
    return new ApiError(400, code, message);
  }

  static unauthorized(message = 'Authentication required.') {
    return new ApiError(401, 'UNAUTHORIZED', message);
  }

  static forbidden(message = 'You do not have permission to do that.') {
    return new ApiError(403, 'FORBIDDEN', message);
  }

  static notFound(code, message) {
    return new ApiError(404, code, message);
  }

  static conflict(code, message) {
    return new ApiError(409, code, message);
  }

  static validation(message, errors) {
    return new ApiError(422, 'VALIDATION_ERROR', message, { errors });
  }

  static tooManyRequests(message = 'Too many requests. Please slow down.') {
    return new ApiError(429, 'RATE_LIMITED', message);
  }
}

module.exports = ApiError;
