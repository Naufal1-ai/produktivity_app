import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError('This platform is not yet supported.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB83HaYH_B5ucaKlcTP5FI1Lyy7oZoM4GU',
    appId: '1:511628765064:android:ce81a98c48bcc1ab38fc3d',
    messagingSenderId: '511628765064',
    projectId: 'keuangan-pribadi-2df3e',
    storageBucket: 'keuangan-pribadi-2df3e.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApQJWCkkdJ4a-VUsAlZJHbg-tljv_Sxhs',
    authDomain: 'keuangan-pribadi-2df3e.firebaseapp.com',
    projectId: 'keuangan-pribadi-2df3e',
    storageBucket: 'keuangan-pribadi-2df3e.firebasestorage.app',
    messagingSenderId: '511628765064',
    appId: '1:511628765064:web:4ba8cbe277fae25138fc3d',
    measurementId: 'G-8KTMRBDXDH',
  );
}
