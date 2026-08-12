const request = require('supertest');
const app = require('../../src/app');

describe('app wiring', () => {
  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ status: 'ok', service: 'certosec-backend' });
  });

  test('unknown routes return the documented 404 shape', async () => {
    const res = await request(app).get('/api/v1/nope');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({
      success: false,
      error: { code: 'NOT_FOUND', message: expect.stringContaining('/api/v1/nope') },
    });
  });

  test('auth login rejects invalid payloads with field-level errors', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'not-an-email', password: '' });
    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.errors).toHaveProperty('email');
    expect(res.body.errors).toHaveProperty('password');
  });

  test('verification endpoints validate their inputs', async () => {
    const badUid = await request(app).post('/api/v1/verify/uid').send({ uid: 'bogus' });
    expect(badUid.status).toBe(422);
    expect(badUid.body.error.code).toBe('VALIDATION_ERROR');

    const badHash = await request(app)
      .post('/api/v1/verify/transaction')
      .send({ txHash: 'not-a-hash' });
    expect(badHash.status).toBe(422);
    expect(badHash.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('GET /verify requires exactly one lookup parameter', async () => {
    const none = await request(app).get('/api/v1/verify');
    expect(none.status).toBe(422);
    expect(none.body.error.code).toBe('VALIDATION_ERROR');

    const both = await request(app)
      .get('/api/v1/verify')
      .query({ uid: 'CERT-2026-000001', txHash: `0x${'a'.repeat(64)}` });
    expect(both.status).toBe(422);
    expect(both.body.error.message).toContain('exactly one');
  });

  test('protected routes reject missing credentials', async () => {
    const res = await request(app).get('/api/v1/students');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });
});
