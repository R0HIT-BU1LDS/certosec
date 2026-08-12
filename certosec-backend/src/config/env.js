const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

function required(name) {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function optional(name, fallback = '') {
  const value = process.env[name];
  return value === undefined || value === '' ? fallback : value;
}

function int(name, fallback) {
  const parsed = parseInt(process.env[name], 10);
  return Number.isNaN(parsed) ? fallback : parsed;
}

module.exports = {
  nodeEnv: optional('NODE_ENV', 'development'),
  isProduction: optional('NODE_ENV', 'development') === 'production',
  port: int('PORT', 3000),
  logFormat: optional('LOG_FORMAT', 'dev'),

  corsOrigins: (optional('CORS_ORIGINS', '') || optional('FRONTEND_URL', 'http://localhost:3000'))
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),

  supabase: {
    url: required('SUPABASE_URL'),
    anonKey: required('SUPABASE_ANON_KEY'),
    serviceRoleKey: required('SUPABASE_SERVICE_ROLE_KEY'),
    jwtSecret: optional('SUPABASE_JWT_SECRET'),
  },

  storage: {
    bucket: optional('STORAGE_BUCKET', 'certificates'),
    maxPdfBytes: int('MAX_PDF_MB', 10) * 1024 * 1024,
    signedUrlExpiry: int('STORAGE_SIGNED_URL_EXPIRY', 3600),
  },

  blockchain: {
    rpcUrl: required('BLOCKCHAIN_RPC_URL'),
    chainId: int('BLOCKCHAIN_CHAIN_ID', 80002),
    privateKey: optional('BLOCKCHAIN_PRIVATE_KEY'),
    contractAddress: optional('CONTRACT_ADDRESS'),
    networkName: optional('NETWORK_NAME', 'Polygon Amoy'),
    confirmations: int('BLOCKCHAIN_CONFIRMATIONS', 1),
  },

  issuer: {
    name: optional('ISSUER_NAME', 'CertoSec University Network'),
  },

  admin: {
    email: optional('ADMIN_EMAIL', '').toLowerCase(),
  },

  app: {
    passwordResetUrl: optional('PASSWORD_RESET_URL', 'http://localhost:3000/auth/reset'),
  },
};
