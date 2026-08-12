import '../../models/auth_session.dart';
import '../../models/user.dart';
import 'api_client.dart';
import 'api_endpoints.dart';
import 'auth_gateway.dart';

/// AuthApi is the HTTP implementation of [AuthGateway].
///
/// It performs the REST calls defined in the backend contract:
///   POST /auth/login            {email, password}
///   POST /auth/logout           (authenticated)
///   POST /auth/forgot-password  {email}
///   GET  /auth/me               (authenticated)
class AuthApi implements AuthGateway {
  AuthApi(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout);
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _client.post(ApiEndpoints.forgotPassword, body: {'email': email});
  }

  @override
  Future<User> fetchCurrentUser() async {
    final response = await _client.get(ApiEndpoints.me);
    return User.fromJson(response.data! as Map<String, dynamic>);
  }
}
