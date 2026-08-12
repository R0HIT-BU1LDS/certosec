import 'user.dart';

/// AuthSession is the complete result of a successful sign-in: the access
/// token, the optional refresh token, and the signed-in user.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final User user;

  /// Parses the login response. Accepted token key names:
  /// `accessToken`, `token`, `access_token`. The user object may be nested
  /// under `user` or (for flat responses) at the top level.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] ?? json['token'] ?? json['access_token'];
    if (token == null || token.toString().isEmpty) {
      throw const FormatException(
        'Login response did not contain an access token.',
      );
    }

    final userValue = json['user'];
    final user = userValue is Map<String, dynamic>
        ? User.fromJson(userValue)
        : User.fromJson(json);

    return AuthSession(
      accessToken: token.toString(),
      refreshToken: (json['refreshToken'] ?? json['refresh_token'])?.toString(),
      user: user,
    );
  }
}
