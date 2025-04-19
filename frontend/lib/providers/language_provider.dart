import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isLanguageSelected = false; // Add this property

  Locale get locale => _locale;
  bool get isLanguageSelected => _isLanguageSelected; // Add this getter

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    _isLanguageSelected = true; // Set to true when language is selected
    
    // Save the selected language to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    await prefs.setBool('isLanguageSelected', true);
    
    notifyListeners();
  }

  Future<bool> tryAutoSetLocale() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('languageCode')) {
      return false;
    }
    
    _locale = Locale(prefs.getString('languageCode')!);
    _isLanguageSelected = prefs.getBool('isLanguageSelected') ?? false;
    
    notifyListeners();
    return _isLanguageSelected;
  }
}