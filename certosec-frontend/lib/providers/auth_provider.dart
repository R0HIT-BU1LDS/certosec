import 'package:flutter/foundation.dart';

import '../core/constants/app_enums.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/api/api_exception.dart';

/// AuthProvider is the single source of truth for the authentication domain.
///
/// It owns:
/// - the tri-state [status] consumed by the router's redirect logic,
/// - the signed-in [User] profile,
/// - the async operations (login / logout / forgot-password / session check)
///   with their loading and error state.
///
/// Screens call these methods and listen via Provider; they never touch the
/// repository, storage, or HTTP directly.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _forgotPasswordLoading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get forgotPasswordLoading => _forgotPasswordLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Boot-time session check: if a token exists, validate it against `/me`.
  ///
  /// - No token        -> signed out (no network).
  /// - Token valid     -> signed in with a fresh profile.
  /// - Token rejected  -> clear session, signed out.
  /// - Network failure -> signed out for now, but the token is kept so a later
  ///   app start can still validate it (avoids destroying a good session on a
  ///   transient outage).
  Future<void> checkSession() async {
    _status = AuthStatus.unknown;
    _errorMessage = null;
    notifyListeners();

    final token = await _repository.readToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await _repository.fetchCurrentUser();
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.kind == ApiExceptionKind.unauthorized) {
        await _repository.clearSession();
      }
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Signs the user in. Returns true on success so callers can react
  /// (navigation itself is handled by the router's redirect).
  Future<bool> login({required String email, required String password}) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();

    try {
      final session = await _repository.login(email: email, password: password);
      _user = session.user;
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ends the session. Never throws — sign-out must always succeed locally.
  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Requests a password reset email. Returns true when the server accepted
  /// the request (regardless of whether the email exists, for privacy).
  Future<bool> forgotPassword(String email) async {
    if (_forgotPasswordLoading) return false;
    _forgotPasswordLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.forgotPassword(email);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _forgotPasswordLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
