import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's locale. Persists the user's choice in SharedPreferences
/// so the language is remembered across app launches.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_language_code';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  /// Loads the previously selected language from SharedPreferences.
  /// Call this once at app startup before building the UI.
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (newLocale == _locale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }
}
