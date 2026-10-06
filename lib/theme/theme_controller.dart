import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current [ThemeMode] and persists the user's choice
/// locally so it survives closing and reopening the app.
///
/// Follows the same lightweight "static ValueNotifier" pattern already
/// used by `AuthService.profileVersion` elsewhere in the app, so
/// `MainApp` can rebuild with a `ValueListenableBuilder` and any screen
/// (e.g. Settings) can read/update it without extra plumbing.
class ThemeController {
  ThemeController._();

  static const _prefsKey = 'theme_mode';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool _loaded = false;

  /// Loads the saved theme preference, if any. Safe to call multiple
  /// times; only reads from disk once. Call this before/while building
  /// the app (e.g. in `main()`), before or after `runApp` - either
  /// works since `MainApp` listens for changes.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      switch (saved) {
        case 'dark':
          themeMode.value = ThemeMode.dark;
          break;
        case 'light':
          themeMode.value = ThemeMode.light;
          break;
        default:
          // No saved preference yet: keep the light default.
          break;
      }
    } catch (_) {
      // If local storage isn't available for some reason, just keep
      // whatever ThemeMode is already in memory (defaults to light).
    }
  }

  /// Whether the app is currently showing the dark theme.
  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  /// Switches between light and dark and saves the choice locally.
  static Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, enabled ? 'dark' : 'light');
    } catch (_) {
      // Preference just won't persist across restarts; the in-memory
      // value above still updates the UI for this session.
    }
  }
}
