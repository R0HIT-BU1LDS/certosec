import '../../models/auth_session.dart';
import '../../models/user.dart';

/// AuthGateway is the contract for the authentication backend.
///
/// The repository depends on this interface (never on the HTTP implementation
/// directly), which lets tests substitute an in-memory fake and keeps the
/// application decoupled from the transport.
abstract interface class AuthGateway {
  Future<AuthSession> login({required String email, required String password});

  /// Ends the server-side session. Implementations should treat failure as
  /// non-fatal (the client always clears local credentials regardless).
  Future<void> logout();

  Future<void> forgotPassword(String email);

  Future<User> fetchCurrentUser();
}
