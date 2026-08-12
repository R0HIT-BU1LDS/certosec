const rateLimit = require('express-rate-limit');

function rateLimitHandler(req, res) {
  return res.status(429).json({
    success: false,
    error: {
      code: 'RATE_LIMITED',
      message: 'Too many requests. Please slow down and try again later.',
    },
  });
}

const baseOptions = {
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
};

/** Login brute-force protection. */
const loginLimiter = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000,
  limit: 10,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many sign-in attempts. Please wait a few minutes.' } },
});

/** Public verification endpoints — prevent automated abuse. */
const verificationLimiter = rateLimit({
  ...baseOptions,
  windowMs: 60 * 1000,
  limit: 30,
});

/** General API throttle. */
const apiLimiter = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000,
  limit: 600,
});

module.exports = { loginLimiter, verificationLimiter, apiLimiter };
