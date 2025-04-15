import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  bool _isLanguageSelected = false;

  Locale get currentLocale => _currentLocale;
  bool get isLanguageSelected => _isLanguageSelected;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    final hasSelectedLanguage = prefs.getBool('isLanguageSelected') ?? false;
    
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
    }
    
    _isLanguageSelected = hasSelectedLanguage;
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _currentLocale = Locale(languageCode);
    _isLanguageSelected = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    await prefs.setBool('isLanguageSelected', true);
    
    notifyListeners();
  }
}