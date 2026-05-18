import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _languageKey = 'language';
  static const String _themeColorKey = 'theme_color';
  static const String _dailyReminderKey = 'daily_reminder';
  static const String _weeklyReminderKey = 'weekly_reminder';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinKey = 'pin';

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  late String _language;
  late int _themeColorValue;
  late bool _dailyReminder;
  late bool _weeklyReminder;
  late bool _pinEnabled;
  String? _pin;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _language = _prefs.getString(_languageKey) ?? 'id';
    _themeColorValue = _prefs.getInt(_themeColorKey) ?? Colors.blue.value;
    _dailyReminder = _prefs.getBool(_dailyReminderKey) ?? false;
    _weeklyReminder = _prefs.getBool(_weeklyReminderKey) ?? false;
    _pinEnabled = _prefs.getBool(_pinEnabledKey) ?? false;
    _pin = _prefs.getString(_pinKey);
    _initialized = true;
  }

  // Language
  String get language => _language;
  set language(String value) {
    _language = value;
    _prefs.setString(_languageKey, value);
  }

  // Theme Color
  Color get themeColor => Color(_themeColorValue);
  set themeColor(Color value) {
    _themeColorValue = value.value;
    _prefs.setInt(_themeColorKey, _themeColorValue);
  }

  // Notifications
  bool get dailyReminder => _dailyReminder;
  set dailyReminder(bool value) {
    _dailyReminder = value;
    _prefs.setBool(_dailyReminderKey, value);
  }

  bool get weeklyReminder => _weeklyReminder;
  set weeklyReminder(bool value) {
    _weeklyReminder = value;
    _prefs.setBool(_weeklyReminderKey, value);
  }

  // Security
  bool get pinEnabled => _pinEnabled;
  set pinEnabled(bool value) {
    _pinEnabled = value;
    _prefs.setBool(_pinEnabledKey, value);
  }

  String? get pin => _pin;
  set pin(String? value) {
    _pin = value;
    if (value != null) {
      _prefs.setString(_pinKey, value);
    } else {
      _prefs.remove(_pinKey);
    }
  }

  // Validate PIN
  bool validatePin(String inputPin) {
    return _pin == inputPin;
  }

  // Clear all settings
  Future<void> clearAll() async {
    await _prefs.clear();
    _initialized = false;
  }
}
