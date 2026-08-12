const { createClient } = require('@supabase/supabase-js');
const env = require('./env');

/**
 * Service-role client. Bypasses Row Level Security, so it is used ONLY
 * server-side for database and storage operations. It must never leave this
 * process (never send the key to the Flutter app, never log it).
 */
const supabase = createClient(env.supabase.url, env.supabase.serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

/**
 * Anon client. Used only for Supabase Auth operations (password grant,
 * password reset). Carries the public anon key, which is safe to use
 * server-side but must never be confused with the service-role key.
 */
const supabaseAnon = createClient(env.supabase.url, env.supabase.anonKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

module.exports = { supabase, supabaseAnon };
