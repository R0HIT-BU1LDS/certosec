const ApiError = require('../utils/ApiError');
const { toProfileJson } = require('../models/profile');

/**
 * AuthService.
 *
 * Login proxies the Supabase Auth password grant so the Flutter app never
 * needs to talk to Supabase directly. The returned access token IS the
 * Supabase access token; the backend verifies it on every protected request.
 * No second password system exists.
 */
class AuthService {
  constructor({ anonAuth, profileRepository, auditService, config }) {
    this.anonAuth = anonAuth;
    this.profileRepository = profileRepository;
    this.auditService = auditService;
    this.config = config;
  }

  async login({ email, password, ipAddress, userAgent }) {
    const { data, error } = await this.anonAuth.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (error || !data.session || !data.user) {
      throw ApiError.unauthorized('Invalid email or password.');
    }

    const authUser = data.user;
    const metadata = authUser.user_metadata || {};

    const profile = await this.profileRepository.upsertForAuthUser(
      {
        id: authUser.id,
        email: authUser.email,
        fullName:
          metadata.full_name || metadata.name || authUser.email.split('@')[0] || '',
        avatarUrl: metadata.avatar_url || metadata.avatarUrl || null,
        institutionName:
          metadata.institution_name || metadata.institution || null,
      },
      this.config.admin.email,
    );

    await this.auditService.log({
      userId: profile.id,
      action: 'LOGIN',
      entityType: 'profile',
      entityId: profile.id,
      ipAddress,
      userAgent,
    });

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at ? data.session.expires_at : null,
      user: toProfileJson(profile),
    };
  }

  async me(userId) {
    const profile = await this.profileRepository.findById(userId);
    if (!profile) {
      throw ApiError.unauthorized();
    }
    return toProfileJson(profile);
  }

  /**
   * Best-effort revocation of the user's Supabase session (kills refresh
   * tokens). Access tokens stay valid until they expire (short-lived), so
   * the client clearing its secure storage is what really ends the session.
   */
  async logout(accessToken) {
    if (!accessToken) return;
    try {
      await this.anonAuth.auth.admin.signOut(accessToken);
    } catch {
      // Non-fatal: the client always clears local session state.
    }
  }

  async forgotPassword(email) {
    try {
      await this.anonAuth.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: this.config.app.passwordResetUrl,
      });
    } catch {
      // Supabase returns success even for unknown emails; stay identical.
    }
    return true;
  }
}

module.exports = AuthService;
