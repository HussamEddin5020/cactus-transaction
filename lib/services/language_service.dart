import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  bool _isRTL = true;

  Locale get locale => _locale;
  bool get isRTL => _isRTL;

  void setLocale(Locale locale) {
    _locale = locale;
    _isRTL = locale.languageCode == 'ar';
    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'ar') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ar'));
    }
  }

  String getText(String ar, String en) {
    return _locale.languageCode == 'ar' ? ar : en;
  }
}

