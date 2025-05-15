import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  // Constructor that loads saved locale
  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

void setLocale(Locale locale) {
  if (locale.languageCode != _locale.languageCode) {
    print('Changing locale from ${_locale.languageCode} to ${locale.languageCode}');
    _locale = locale;
    notifyListeners(); // This is crucial
  }
}

  void clearLocale() {
    _locale = const Locale('en');
    _saveLocale('en'); // Save the default locale
    notifyListeners();
  }

  // Load the saved locale
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('language');
      if (language != null) {
        print('Loading saved locale: $language');
        _locale = Locale(language);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved locale: $e');
    }
  }

  // Save the locale
  Future<void> _saveLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      print('Saved locale: $languageCode');
    } catch (e) {
      print('Error saving locale: $e');
    }
  }
}