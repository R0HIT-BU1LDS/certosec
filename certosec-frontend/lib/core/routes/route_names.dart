/// RouteNames is the canonical list of every route in the app.
///
/// Screens are referenced by these constants (never by raw strings), so a
/// rename touches exactly one file. The registration timing column documents
/// which phase activates each route; route registration happens in the
/// AppRouter as the corresponding screen is built.
abstract final class RouteNames {
  // Public — no authentication required.
  static const String splash = '/splash';
  static const String login = '/login';
  static const String verification = '/verify';
  static const String verificationResult = '/verify/result';

  // Private — requires an authenticated session.
  static const String dashboard = '/dashboard';
  static const String students = '/students';
  static const String studentAdd = '/students/add';
  static const String studentDetails = '/students/:id';
  static const String studentEdit = '/students/:id/edit';
  static const String certificates = '/certificates';
  static const String certificateDetails = '/certificates/:uid';
  static const String issueCertificate = '/certificates/issue';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// Routes reachable without a session. Redirect logic treats everything not
  /// in this set as protected.
  static const List<String> publicRoutes = [
    splash,
    login,
    verification,
    verificationResult,
  ];

  /// Derives a concrete path from a pattern route, e.g.
  /// `detail(RouteNames.certificateDetails, 'CERT-2026-000001')`.
  static String detail(String pattern, String value) =>
      pattern.replaceFirst(':id', value).replaceFirst(':uid', value);

  /// Concrete result route carrying the UID to verify, e.g.
  /// `/verify/result?uid=CERT-2026-000001`.
  static String verificationResultWith(String uid) =>
      '$verificationResult?uid=$uid';

  /// Concrete result route carrying the transaction hash to verify, e.g.
  /// `/verify/result?txHash=0x...`.
  static String verificationResultWithHash(String txHash) =>
      '$verificationResult?txHash=$txHash';
}
