import '../../core/constants/app_enums.dart';
import '../../core/constants/storage_keys.dart';
import 'secure_storage_service.dart';

/// SettingsStorage is the abstraction over persisted user preferences.
///
/// Production is backed by [SettingsStorageService]; tests inject an in-memory
/// implementation so the theme preference round-trip is testable without
/// platform channels.
abstract interface class SettingsStorage {
  Future<ThemePreference> readThemePreference();

  Future<void> writeThemePreference(ThemePreference preference);
}

/// SettingsStorageService persists non-sensitive user preferences (currently
/// the theme mode) back to the same secure store so the dependency stack stays
/// exactly as specified — no extra packages required.
///
/// This is intentionally a separate service from SecureStorageService even
/// though they share a backing store: it documents that these values are
/// preferences, not secrets, and gives the settings feature a clear seam.
class SettingsStorageService implements SettingsStorage {
  SettingsStorageService(this._secureStorage);

  final SecureStorageService _secureStorage;

  @override
  Future<ThemePreference> readThemePreference() async {
    final raw = await _secureStorage.raw.read(key: StorageKeys.themeMode);
    return ThemePreference.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemePreference.system,
    );
  }

  @override
  Future<void> writeThemePreference(ThemePreference preference) async {
    await _secureStorage.raw.write(
      key: StorageKeys.themeMode,
      value: preference.name,
    );
  }
}
