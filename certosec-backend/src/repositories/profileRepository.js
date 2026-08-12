const { toApiError } = require('../utils/db');

/**
 * ProfileRepository owns `profiles` rows. Profiles map 1:1 to Supabase Auth
 * users. Role is ALWAYS determined server-side (never from client input).
 */
class ProfileRepository {
  constructor(db) {
    this.db = db;
  }

  async findById(id) {
    const { data, error } = await this.db
      .from('profiles')
      .select('*')
      .eq('id', id)
      .maybeSingle();
    if (error) throw toApiError(error, 'find profile');
    return data;
  }

  async findByEmail(email) {
    const { data, error } = await this.db
      .from('profiles')
      .select('*')
      .eq('email', email.toLowerCase())
      .maybeSingle();
    if (error) throw toApiError(error, 'find profile by email');
    return data;
  }

  /**
   * Ensures a profile exists for an authenticated user. If the profile does
   * not exist yet it is created (role `verifier`, or `admin` when the email is
   * the configured bootstrap admin). Existing roles are NEVER overwritten.
   */
  async upsertForAuthUser(authUser, adminEmail) {
    const existing = await this.findById(authUser.id);
    if (existing) {
      const { error } = await this.db
        .from('profiles')
        .update({
          email: authUser.email.toLowerCase(),
          full_name: authUser.fullName,
          avatar_url: authUser.avatarUrl || null,
        })
        .eq('id', authUser.id);
      if (error) throw toApiError(error, 'refresh profile');
      return { ...existing, email: authUser.email.toLowerCase(), full_name: authUser.fullName };
    }

    const role = authUser.email.toLowerCase() === adminEmail ? 'admin' : 'verifier';
    const { data, error } = await this.db
      .from('profiles')
      .insert({
        id: authUser.id,
        email: authUser.email.toLowerCase(),
        full_name: authUser.fullName,
        role,
        institution_name: authUser.institutionName || null,
        avatar_url: authUser.avatarUrl || null,
      })
      .select('*')
      .single();
    if (error) throw toApiError(error, 'create profile');
    return data;
  }
}

module.exports = ProfileRepository;
