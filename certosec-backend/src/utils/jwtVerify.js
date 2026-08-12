const { createRemoteJWKSet, jwtVerify } = require('jose');
const env = require('../config/env');

/**
 * Verifies Supabase access tokens against the project's published public keys
 * (JWKS). Modern Supabase projects sign tokens with ES256 using a per-project
 * key pair — the shared SUPABASE_JWT_SECRET cannot verify those, so we verify
 * against `{SUPABASE_URL}/auth/v1/.well-known/jwks.json` instead.
 *
 * The remote JWKS set is fetched once, cached, and refreshed automatically by
 * `jose` (with a built-in failure cooldown), so verification stays local and
 * fast after the first request.
 */
const jwks = createRemoteJWKSet(
  new URL(`${env.supabase.url.replace(/\/$/, '')}/auth/v1/.well-known/jwks.json`),
);

/**
 * @returns {Promise<object>} decoded token payload
 * @throws {jose.errors.JOSEError} on invalid/expired tokens
 */
async function verifyAccessToken(token) {
  const { payload } = await jwtVerify(token, jwks, {
    algorithms: ['ES256', 'HS256'],
  });
  return payload;
}

module.exports = { verifyAccessToken };
