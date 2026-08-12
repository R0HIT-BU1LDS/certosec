const ApiError = require('../utils/ApiError');

/**
 * requireRole guards a route to specific roles. The role is read from
 * `req.user`, which requireAuth populated from the profiles table — never from
 * client input.
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(ApiError.unauthorized());
    }
    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden());
    }
    return next();
  };
}

/** Alias: only admins may pass. */
const requireAdmin = requireRole('admin');

module.exports = { requireRole, requireAdmin };
