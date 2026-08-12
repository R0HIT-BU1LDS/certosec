jest.mock('../../src/services/index', () => ({
  repositories: {
    profileRepository: {
      findById: jest.fn(),
      upsertForAuthUser: jest.fn(),
    },
  },
}));

jest.mock('../../src/utils/jwtVerify', () => ({
  verifyAccessToken: jest.fn(),
}));

const { requireAuth } = require('../../src/middleware/authenticate');

const { repositories } = require('../../src/services/index');
const { profileRepository } = repositories;
const { verifyAccessToken } = require('../../src/utils/jwtVerify');

const SUB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

function makeRequest(overrides = {}) {
  return { headers: {}, ...overrides };
}

function makeResponse() {
  const res = { statusCode: null, body: null };
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (body) => {
    res.body = body;
    return res;
  };
  return res;
}

function verificationError(code, message) {
  const err = new Error(message);
  err.code = code;
  return err;
}

function runAuth(req) {
  const res = makeResponse();
  const next = jest.fn();
  return requireAuth(req, res, next).then(() => ({ res, next }));
}

describe('requireAuth middleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    profileRepository.findById.mockResolvedValue({
      id: SUB,
      email: 'admin@certosec.com',
      full_name: 'Admin',
      role: 'admin',
      institution_name: null,
    });
    verifyAccessToken.mockResolvedValue({
      sub: SUB,
      email: 'admin@certosec.com',
      role: 'authenticated',
    });
  });

  test('rejects requests without a Bearer token (401)', async () => {
    const { next } = await runAuth(makeRequest());
    const err = next.mock.calls[0][0];
    expect(err.statusCode).toBe(401);
    expect(err.code).toBe('UNAUTHORIZED');
  });

  test('rejects a token that fails signature verification (401)', async () => {
    verifyAccessToken.mockRejectedValue(verificationError('ERR_JWS_INVALID', 'signature invalid'));
    const { next } = await runAuth(
      makeRequest({ headers: { authorization: 'Bearer not-a-real-token' } }),
    );
    const err = next.mock.calls[0][0];
    expect(err.statusCode).toBe(401);
    expect(err.code).toBe('UNAUTHORIZED');
  });

  test('rejects an expired token with a session message (401)', async () => {
    verifyAccessToken.mockRejectedValue(verificationError('ERR_JWT_EXPIRED', 'expired'));
    const { next } = await runAuth(
      makeRequest({ headers: { authorization: 'Bearer eyJhbGciOiJFUzI1NiJ9.eyJleHAiOjB9.sig' } }),
    );
    const err = next.mock.calls[0][0];
    expect(err.statusCode).toBe(401);
    expect(err.message).toContain('expired');
  });

  test('rejects a token when the JWKS key cannot be fetched (401)', async () => {
    verifyAccessToken.mockRejectedValue(verificationError('ERR_JWKS_TIMEOUT', 'fetch failed'));
    const { next } = await runAuth(
      makeRequest({ headers: { authorization: 'Bearer some-token' } }),
    );
    expect(next.mock.calls[0][0]).toMatchObject({ statusCode: 401 });
  });

  test('attaches the user (role from profiles, never from the JWT) and calls next', async () => {
    const token = 'valid.jwt.token';
    const req = makeRequest({ headers: { authorization: `Bearer ${token}` } });
    const { res, next } = await runAuth(req);
    expect(next).toHaveBeenCalledWith();
    expect(req.user).toMatchObject({
      id: SUB,
      email: 'admin@certosec.com',
      role: 'admin',
    });
    expect(req.authToken).toBe(token);
    expect(res.statusCode).toBeNull();
  });

  test('auto-provisions a profile for a user without one', async () => {
    profileRepository.findById.mockResolvedValue(null);
    profileRepository.upsertForAuthUser.mockResolvedValue({
      id: SUB,
      email: 'verifier@certosec.com',
      full_name: 'Verifier',
      role: 'verifier',
      institution_name: null,
    });
    verifyAccessToken.mockResolvedValue({
      sub: SUB,
      email: 'verifier@certosec.com',
      user_metadata: { full_name: 'Verifier' },
    });
    const req = makeRequest({ headers: { authorization: 'Bearer valid.jwt.token' } });
    await runAuth(req);
    expect(profileRepository.upsertForAuthUser).toHaveBeenCalledWith(
      expect.objectContaining({ id: SUB, email: 'verifier@certosec.com' }),
      expect.any(String),
    );
    expect(req.user.role).toBe('verifier');
  });
});
