import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// AppConfig is the single source of truth for environment-level settings.
///
/// Everything here is resolved once at runtime. API endpoints and the
/// verification URL can be overridden at build time via
/// `--dart-define=API_BASE_URL=...`, which is how production builds target the
/// real backend without touching source code.
abstract final class AppConfig {
  static const String appName = 'CertoSec';
  static const String appTagline = 'Blockchain Verified Certificates';
  static const String appVersion = '2.0.0';
  static const String orgName = 'CertoSec University Network';

  /// Backend base URL. Resolved in priority order:
  /// 1. Compile-time override (production).
  /// 2. Platform-aware development default (Android emulator vs everything else).
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  /// HTTP timeout for every request to the backend.
  static const Duration apiTimeout = Duration(seconds: 20);

  /// Base URL embedded in certificate QR codes. The QR payload is always of the
  /// form `$verificationBaseUrl?uid=<CERTIFICATE_UID>`. No blockchain data is
  /// ever placed inside a QR code.
  static const String verificationBaseUrl = String.fromEnvironment(
    'VERIFY_BASE_URL',
    defaultValue: 'https://verify.certosec.org/verify',
  );

  /// Minimum time the branded splash screen stays visible.
  static const Duration minimumSplashDuration = Duration(milliseconds: 1400);

  /// Certificate UID format used by the platform, e.g. `CERT-2026-000001`.
  static const String certificateUidPrefix = 'CERT';

  /// Default page size for paginated list endpoints.
  static const int defaultPageSize = 20;
}
