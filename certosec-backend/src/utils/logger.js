/* eslint-disable no-console */
const env = require('../config/env');

const LEVELS = ['error', 'warn', 'info', 'debug'];

function log(level, message, extra) {
  if (env.nodeEnv === 'test') return;
  const line = [`[${new Date().toISOString()}] [${level.toUpperCase()}]`, message];
  if (extra !== undefined) line.push(JSON.stringify(extra));
  console[level === 'debug' ? 'log' : level](line.join(' '));
}

module.exports = {
  error: (message, extra) => log('error', message, extra),
  warn: (message, extra) => log('warn', message, extra),
  info: (message, extra) => log('info', message, extra),
  debug: (message, extra) => log('debug', message, extra),
  LEVELS,
};
