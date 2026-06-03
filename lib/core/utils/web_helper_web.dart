import 'dart:js_interop';

@JS('removeSplashFromWeb')
external void removeSplashFromWeb();

/// Web implementation to remove splash screen from HTML DOM.
void removeSplash() {
  try {
    removeSplashFromWeb();
  } catch (_) {
    // Suppress errors in case it's called in environments where the method isn't defined
  }
}
