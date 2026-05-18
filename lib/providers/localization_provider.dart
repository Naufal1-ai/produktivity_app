import 'package:flutter/material.dart';
import 'package:productivity/services/settings_service.dart';

class LocalizationProvider extends ChangeNotifier {
  final SettingsService _settingsService;
  Locale _locale;

  LocalizationProvider(this._settingsService)
      : _locale = Locale(_settingsService.language);

  Locale get locale => _locale;

  void setLocale(String languageCode) {
    _locale = Locale(languageCode);
    _settingsService.language = languageCode;
    notifyListeners();
  }

  String get currentLanguage => _settingsService.language;
}
