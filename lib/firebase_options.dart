import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return desktop;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBnaHtZw7wAXr1ILBZHkXL3ErPFSksKOAQ',
    appId: '1:183472480070:web:a76427a6f9a9d766de8f47',
    messagingSenderId: '183472480070',
    projectId: 'learnable-fb251',
    authDomain: 'learnable-fb251.firebaseapp.com',
    storageBucket: 'learnable-fb251.firebasestorage.app',
    measurementId: 'G-N5NM1X7XLC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBnaHtZw7wAXr1ILBZHkXL3ErPFSksKOAQ',
    appId: '1:183472480070:android:adc6ffa56045627cde8f47',
    messagingSenderId: '183472480070',
    projectId: 'learnable-fb251',
    storageBucket: 'learnable-fb251.firebasestorage.app',
  );

  static const FirebaseOptions desktop = web;
}
