import 'package:flutter/material.dart';

import '../core/constants/app_enums.dart';
import '../services/storage/settings_storage_service.dart';

/// ThemeProvider owns the appearance preference (system / light / dark).
///
/// The preference is persisted so the choice survives app restarts, and it
/// loads during the splash sequence to avoid a visible theme flash on boot.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._settingsStorage);

  final SettingsStorage _settingsStorage;

  ThemePreference _preference = ThemePreference.system;

  ThemePreference get preference => _preference;

  ThemeMode get themeMode => switch (_preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  Future<void> load() async {
    _preference = await _settingsStorage.readThemePreference();
    notifyListeners();
  }

  Future<void> setPreference(ThemePreference preference) async {
    _preference = preference;
    notifyListeners();
    await _settingsStorage.writeThemePreference(preference);
  }
}
