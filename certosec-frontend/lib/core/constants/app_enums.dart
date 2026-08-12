/// AppEnums defines the closed set of domain states shared across the app.
/// Enums stay in `core` so every layer (UI, providers, models) can reference
/// them without creating circular imports.
enum AuthStatus {
  /// No session check has completed yet (used by the splash screen).
  unknown,

  /// A valid token is present and the user is signed in.
  authenticated,

  /// No valid token is present.
  unauthenticated,
}

enum UserRole {
  admin,
  verifier;

  String get label => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.verifier => 'Verifier',
  };
}

enum CertificateStatus {
  pending,
  issued,
  verified,
  revoked;

  String get label => switch (this) {
    CertificateStatus.pending => 'Pending',
    CertificateStatus.issued => 'Issued',
    CertificateStatus.verified => 'Verified',
    CertificateStatus.revoked => 'Revoked',
  };

  /// Case-insensitive parse; unknown values fall back to [pending].
  static CertificateStatus fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    for (final status in CertificateStatus.values) {
      if (status.name.toLowerCase() == raw) return status;
    }
    return CertificateStatus.pending;
  }
}

enum VerificationStatus {
  valid,
  invalid,
  tampered;

  String get label => switch (this) {
    VerificationStatus.valid => 'Valid',
    VerificationStatus.invalid => 'Invalid',
    VerificationStatus.tampered => 'Tampered',
  };

  /// Case-insensitive parse; unknown values fall back to [invalid].
  static VerificationStatus fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    for (final status in VerificationStatus.values) {
      if (status.name.toLowerCase() == raw) return status;
    }
    return VerificationStatus.invalid;
  }
}

/// User-controlled appearance. `system` follows the OS setting.
enum ThemePreference { system, light, dark }
