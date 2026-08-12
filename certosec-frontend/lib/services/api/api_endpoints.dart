/// ApiEndpoints is the canonical map of REST paths. Every HTTP call in the app
/// references these constants — never raw path strings — so endpoint changes
/// are one-file changes.
abstract final class ApiEndpoints {
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String logout = '$auth/logout';
  static const String forgotPassword = '$auth/forgot-password';
  static const String me = '$auth/me';

  static const String dashboard = '/dashboard';
  static const String dashboardStats = '$dashboard/stats';

  static const String students = '/students';

  /// Endpoint for a single student resource. Callers supply the id.
  static String student(String id) => '$students/$id';

  static const String certificates = '/certificates';

  /// Endpoint for a single certificate resource. Callers supply the uid.
  static String certificate(String uid) => '$certificates/$uid';

  static const String issueCertificate = '$certificates/issue';

  /// Public, unauthenticated certificate verification endpoint.
  static const String verify = '/verify';
}
