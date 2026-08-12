/// SessionStorage is the abstraction over wherever session secrets are
/// persisted.
///
/// Production uses [SecureStorageService] (hardware-backed keystore/keychain).
/// Tests inject an in-memory implementation, which keeps the whole app testable
/// without mocking platform channels. All dependencies that need to persist a
/// session should depend on this interface, never on a concrete plugin.
abstract interface class SessionStorage {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String token);

  /// Clears every stored secret. Called on logout.
  Future<void> clearSession();
}
