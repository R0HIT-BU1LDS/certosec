process.env.SUPABASE_URL = process.env.SUPABASE_URL || 'https://certosec-test.supabase.co';
process.env.SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'test-service-role-key';
process.env.SUPABASE_JWT_SECRET = process.env.SUPABASE_JWT_SECRET || 'test-supabase-jwt-secret';
process.env.BLOCKCHAIN_RPC_URL = process.env.BLOCKCHAIN_RPC_URL || 'https://rpc.amoy.test';
process.env.BLOCKCHAIN_CHAIN_ID = process.env.BLOCKCHAIN_CHAIN_ID || '80002';
process.env.BLOCKCHAIN_PRIVATE_KEY =
  process.env.BLOCKCHAIN_PRIVATE_KEY ||
  '0x0000000000000000000000000000000000000000000000000000000000000001';
process.env.CONTRACT_ADDRESS =
  process.env.CONTRACT_ADDRESS || '0x0000000000000000000000000000000000000001';
process.env.NETWORK_NAME = process.env.NETWORK_NAME || 'Polygon Amoy (test)';
process.env.NODE_ENV = 'test';
