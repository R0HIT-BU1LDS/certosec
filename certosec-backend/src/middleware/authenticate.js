const ApiError = require('../utils/ApiError');
const { verifyAccessToken } = require('../utils/jwtVerify');
const { repositories } = require('../services/index');
const env = require('../config/env');

const { profileRepository } = repositories;

function extractBearerToken(req) {
  const header = req.headers.authorization || '';
  const match = /^Bearer\s+(.+)$/i.exec(header);
  return match ? match[1] : null;
}

/**
 * requireAuth — verifies the Supabase access token.
 *
 * Tokens are verified LOCALLY against the project's public keys (JWKS, ES256
 * for modern projects). The user's application role is then loaded from the
 * `profiles` table; the role claim inside the Supabase JWT is ignored because
 * it only carries the Supabase auth role ('authenticated'), never the app
 * role. A role supplied by the client is never trusted.
 *
 * A missing profile is auto-provisioned (role: verifier, or admin for the
 * configured bootstrap email) so first-time logins work without manual setup.
 */
async function requireAuth(req, res, next) {
  try {
    const token = extractBearerToken(req);
    if (!token) {
      throw ApiError.unauthorized();
    }

    let payload;
    try {
      payload = await verifyAccessToken(token);
    } catch (err) {
      if (err && err.code === 'ERR_JWT_EXPIRED') {
        throw ApiError.unauthorized('Your session has expired. Please sign in again.');
      }
      throw ApiError.unauthorized('Your session token is invalid. Please sign in again.');
    }

    if (!payload.sub) {
      throw ApiError.unauthorized();
    }

    let profile = await profileRepository.findById(payload.sub);
    if (!profile) {
      const metadata = payload.user_metadata || {};
      profile = await profileRepository.upsertForAuthUser(
        {
          id: payload.sub,
          email: payload.email || '',
          fullName: metadata.full_name || metadata.name || payload.email || '',
          avatarUrl: metadata.avatar_url || null,
          institutionName: metadata.institution_name || null,
        },
        env.admin.email,
      );
    }

    req.user = {
      id: profile.id,
      email: profile.email,
      name: profile.full_name,
      role: profile.role,
      institutionName: profile.institution_name || null,
      profile,
    };
    req.authToken = token;
    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = { requireAuth, extractBearerToken };
