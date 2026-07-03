// File generated manually from Firebase Console credentials
// Project: family-pulse-sznzoj

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return web;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCdguC33eGfgAZSjVqCGdYET2m6KwCHvUY',
    authDomain: 'family-pulse-sznzoj.firebaseapp.com',
    projectId: 'family-pulse-sznzoj',
    storageBucket: 'family-pulse-sznzoj.firebasestorage.app',
    messagingSenderId: '172467535450',
    appId: '1:172467535450:web:eefdc074f5ca2a970b2263',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdguC33eGfgAZSjVqCGdYET2m6KwCHvUY',
    appId: '1:172467535450:android:741a362ddedb7d5f0b2263',
    messagingSenderId: '172467535450',
    projectId: 'family-pulse-sznzoj',
    storageBucket: 'family-pulse-sznzoj.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCdguC33eGfgAZSjVqCGdYET2m6KwCHvUY',
    appId: '1:172467535450:ios:eefdc074f5ca2a970b2263',
    messagingSenderId: '172467535450',
    projectId: 'family-pulse-sznzoj',
    storageBucket: 'family-pulse-sznzoj.firebasestorage.app',
    iosBundleId: 'com.familypulse.familyPulse',
  );
}