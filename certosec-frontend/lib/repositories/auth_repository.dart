import '../models/auth_session.dart';
import '../models/user.dart';
import '../services/api/api_exception.dart';
import '../services/api/auth_gateway.dart';
import '../services/storage/session_storage.dart';

/// AuthRepository is the single orchestrator for authentication business
/// rules. It composes the [AuthGateway] (remote) with the [SessionStorage]
/// (local secrets) and exposes clean high-level operations to AuthProvider.
///
/// Responsibility split:
/// - Gateway: transport only (knows HTTP, knows nothing about storage).
/// - Repository: applies rules (persist tokens only on success, always clear
///   on logout, decide whether a token is worth validating).
class AuthRepository {
  AuthRepository({
    required AuthGateway gateway,
    required SessionStorage storage,
  }) : _gateway = gateway,
       _storage = storage;

  final AuthGateway _gateway;
  final SessionStorage _storage;

  /// Signs in and persists the session only after the server confirms success.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _gateway.login(email: email, password: password);
    await _storage.writeToken(session.accessToken);
    if (session.refreshToken != null) {
      await _storage.writeRefreshToken(session.refreshToken!);
    }
    return session;
  }

  /// Ends the session everywhere: server-side call is best-effort (a network
  /// failure must not prevent local sign-out), and local secrets are always
  /// wiped.
  Future<void> logout() async {
    try {
      await _gateway.logout();
    } on ApiException {
      // Local sign-out must succeed even if the server is unreachable.
    }
    await _storage.clearSession();
  }

  Future<bool> forgotPassword(String email) async {
    await _gateway.forgotPassword(email);
    return true;
  }

  /// Validates the persisted token by fetching the current profile.
  Future<User> fetchCurrentUser() => _gateway.fetchCurrentUser();

  Future<String?> readToken() => _storage.readToken();

  Future<void> clearSession() => _storage.clearSession();
}
