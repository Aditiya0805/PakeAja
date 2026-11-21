// Konfigurasi Firebase PakeAja (mendukung Web, Android, iOS, dan Desktop/macOS)
// Membaca nilai dari file .env dengan fallback otomatis string hardcoded
// agar aplikasi tidak pernah mengalami crash/layar putih di web hosting atau device apa pun.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String _normalizeApiKey(String key) {
    // Memperbaiki kemungkinan salah ketik/OCR pada API Key Firebase:
    // 'NLtAm6rCYeqZD8nQ2lvJa9pKA' -> 'NltAmGrCYeqZDBnQ2lvJa9pKA'
    if (key.contains('NLtAm6r') || key.contains('ZD8nQ2lv')) {
      return 'AIzaSyCH156ZE1NltAmGrCYeqZDBnQ2lvJa9pKA';
    }
    return key;
  }

  static String _envOrFallback(String key, String fallback) {
    try {
      final value = dotenv.env[key]?.trim();
      if (value != null && value.isNotEmpty) {
        if (key.contains('API_KEY')) {
          return _normalizeApiKey(value);
        }
        return value;
      }
    } catch (_) {}
    return fallback;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _envOrFallback(
          'FIREBASE_ANDROID_API_KEY',
          'AIzaSyBbH1pmRa6P6G8I6VOPNZdgbtDiyfjvZ4o',
        ),
        appId: _envOrFallback(
          'FIREBASE_ANDROID_APP_ID',
          '1:548065215093:android:9fc44bb9b04d953c106e3c',
        ),
        messagingSenderId: _envOrFallback(
          'FIREBASE_MESSAGING_SENDER_ID',
          '548065215093',
        ),
        projectId: _envOrFallback(
          'FIREBASE_PROJECT_ID',
          'pakeaja',
        ),
        storageBucket: _envOrFallback(
          'FIREBASE_STORAGE_BUCKET',
          'pakeaja.firebasestorage.app',
        ),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _envOrFallback(
          'FIREBASE_IOS_API_KEY',
          'AIzaSyDUBw4d_0pCeAAzz6UVzySAsaWN9W587O0',
        ),
        appId: _envOrFallback(
          'FIREBASE_IOS_APP_ID',
          '1:548065215093:ios:ebbafda2afc0477e106e3c',
        ),
        messagingSenderId: _envOrFallback(
          'FIREBASE_MESSAGING_SENDER_ID',
          '548065215093',
        ),
        projectId: _envOrFallback(
          'FIREBASE_PROJECT_ID',
          'pakeaja',
        ),
        storageBucket: _envOrFallback(
          'FIREBASE_STORAGE_BUCKET',
          'pakeaja.firebasestorage.app',
        ),
        iosBundleId: _envOrFallback(
          'FIREBASE_IOS_BUNDLE_ID',
          'com.example.pakeaja',
        ),
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _envOrFallback(
          'FIREBASE_WEB_API_KEY',
          'AIzaSyCH156ZE1NltAmGrCYeqZDBnQ2lvJa9pKA',
        ),
        appId: _envOrFallback(
          'FIREBASE_WEB_APP_ID',
          '1:548065215093:web:a6471475a6691238106e3c',
        ),
        messagingSenderId: _envOrFallback(
          'FIREBASE_MESSAGING_SENDER_ID',
          '548065215093',
        ),
        projectId: _envOrFallback(
          'FIREBASE_PROJECT_ID',
          'pakeaja',
        ),
        authDomain: _envOrFallback(
          'FIREBASE_WEB_AUTH_DOMAIN',
          'pakeaja.firebaseapp.com',
        ),
        storageBucket: _envOrFallback(
          'FIREBASE_STORAGE_BUCKET',
          'pakeaja.firebasestorage.app',
        ),
      );
}
