// Konfigurasi Firebase diambil secara aman dari file .env menggunakan flutter_dotenv.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String _requireEnv(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Environment variable "$key" belum diset di file .env.',
      );
    }
    return value;
  }

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
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak didukung di platform ini.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _requireEnv('FIREBASE_ANDROID_API_KEY'),
        appId: _requireEnv('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _requireEnv('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _requireEnv('FIREBASE_PROJECT_ID'),
        storageBucket: _requireEnv('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _requireEnv('FIREBASE_IOS_API_KEY'),
        appId: _requireEnv('FIREBASE_IOS_APP_ID'),
        messagingSenderId: _requireEnv('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _requireEnv('FIREBASE_PROJECT_ID'),
        storageBucket: _requireEnv('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _requireEnv('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _requireEnv('FIREBASE_WEB_API_KEY'),
        appId: _requireEnv('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _requireEnv('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _requireEnv('FIREBASE_PROJECT_ID'),
        authDomain: _requireEnv('FIREBASE_WEB_AUTH_DOMAIN'),
        storageBucket: _requireEnv('FIREBASE_STORAGE_BUCKET'),
      );
}
