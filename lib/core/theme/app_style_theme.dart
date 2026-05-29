enum AppStyleTheme {
  modern,
  saweriaClassic,
}

extension AppStyleThemeLabel on AppStyleTheme {
  String get label {
    switch (this) {
      case AppStyleTheme.modern:
        return 'Modern';
      case AppStyleTheme.saweriaClassic:
        return 'Saweria Klasik';
    }
  }
}
