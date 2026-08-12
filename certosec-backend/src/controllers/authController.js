const asyncHandler = require('../utils/asyncHandler');
const { ok, noContent } = require('../utils/responses');
const { authService } = require('../services/index');

const login = asyncHandler(async (req, res) => {
  const session = await authService.login({
    email: req.body.email,
    password: req.body.password,
    ipAddress: req.ip || null,
    userAgent: req.get('user-agent') || null,
  });
  ok(res, session);
});

const me = asyncHandler(async (req, res) => {
  const user = await authService.me(req.user.id);
  ok(res, user);
});

const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.authToken || null);
  noContent(res);
});

const forgotPassword = asyncHandler(async (req, res) => {
  await authService.forgotPassword(req.body.email);
  ok(res, {
    message: 'If that email address is registered, a password reset link has been sent.',
  });
});

module.exports = { login, me, logout, forgotPassword };
