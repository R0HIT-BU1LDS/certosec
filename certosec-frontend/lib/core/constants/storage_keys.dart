/// StorageKeys centralizes every key used to persist data, so key names are
/// spelled once and reused everywhere. Tokens live in secure storage only.
abstract final class StorageKeys {
  static const String authToken = 'certosec.auth_token';
  static const String refreshToken = 'certosec.refresh_token';
  static const String userProfile = 'certosec.user_profile';
  static const String themeMode = 'certosec.theme_mode';
}
