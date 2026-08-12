import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/storage_keys.dart';
import 'session_storage.dart';

/// SecureStorageService is the production implementation of [SessionStorage].
///
/// It wraps flutter_secure_storage, which uses the platform's hardware-backed
/// keychain/keystore (Keychain on iOS, Android Keystore on Android). Nothing
/// sensitive is ever written to SharedPreferences or plain files.
///
/// Note on web: flutter_secure_storage on web uses WebCrypto-backed storage,
/// which is still best-effort. Production web builds should rely on the
/// backend enforcing auth for sensitive actions.
class SecureStorageService implements SessionStorage {
  SecureStorageService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Low-level access for non-sensitive settings that share the same backing
  /// store (used by SettingsStorageService).
  FlutterSecureStorage get raw => _storage;

  @override
  Future<String?> readToken() => _storage.read(key: StorageKeys.authToken);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: StorageKeys.authToken, value: token);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  /// Clears every secret. Called on logout so no session data survives.
  @override
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.authToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.userProfile),
    ]);
  }
}
