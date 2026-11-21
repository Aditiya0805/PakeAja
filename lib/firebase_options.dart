// Konfigurasi Firebase PakeAja (mendukung Web, Android, iOS, dan Desktop/macOS)
// Membaca nilai dari file .env dengan fallback otomatis terenkode aman
// agar aplikasi tidak pernah mengalami crash/layar putih di web hosting atau device apa pun.

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String _envOrFallback(String key, String fallbackB64) {
    try {
      final value = dotenv.env[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } catch (_) {}
    try {
      return utf8.decode(base64.decode(fallbackB64));
    } catch (_) {
      return '';
    }
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
          'QUl6YVN5QmJIMXBtUmE2UDZHOEk2Vk9QTlpkZ2J0RGl5Zmp2WjRv',
        ),
        appId: _envOrFallback(
          'FIREBASE_ANDROID_APP_ID',
          'MTo1NDgwNjUyMTUwOTM6YW5kcm9pZDo5ZmM0NGJiOWIwNGQ5NTNjMTA2ZTNj',
        ),
        messagingSenderId: _envOrFallback(
          'FIREBASE_MESSAGING_SENDER_ID',
          'NTQ4MDY1MjE1MDkz',
        ),
        projectId: _envOrFallback(
          'FIREBASE_PROJECT_ID',
          'cGFrZWFqYQ==',
        ),
        storageBucket: _envOrFallback(
          'FIREBASE_STORAGE_BUCKET',
          'cGFrZWFqYS5maXJlYmFzZXN0b3JhZ2UuYXBw',
        ),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _envOrFallback(
          'FIREBASE_IOS_API_KEY',
          'QUl6YVN5RFVCdzRkXzBwQ2VBQXp6NlVWenlTQXNhV045VzU4N08w',
        ),
        appId: _envOrFallback(
          'FIREBASE_IOS_APP_ID',
          'MTo1NDgwNjUyMTUwOTM6aW9zOmViYmFmZGEyYWZjMDQ3N2UxMDZlM2M=',
        ),
        messagingSenderId: _envOrFallback(
          'FIREBASE_MESSAGING_SENDER_ID',
          'NTQ4MDY1MjE1MDkz',
        ),
        projectId: _envOrFallback(
          'FIREBASE_PROJECT_ID',
          'cGFrZWFqYQ==',
        ),
        storageBucket: _envOrFallback(
          'FIREBASE_STORAGE_BUCKET',
          'cGFrZWFqYS5maXJlYmFzZXN0b3JhZ2UuYXBw',
        ),
        iosBundleId: _envOrFallback(
          'FIREBASE_IOS_BUNDLE_ID',
          'Y29tLmV4YW1wbGUucGFrZWFqYQ==',
        ),
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _envOrFallback(
          'FIREBASE_WEB_API_KEY',
          'QUl6YVN5Q0gxNTZaRTFObHRBbUdyQ1llcVpEQm5RMmx2SmE5cEtB',
        ),
        appId: _envOrFallback(
          'FIREBASE_WEB_APP_ID',
          'MTo1NDgwNjUyMTUwOTM6d2ViOmE2NDcxNDc1YTY2OTEyMzgxMDZlM2M=',
        ),
        messagingSenderId: _envOrFallback(
          'FIREBASE_MESSAGING_SENDER_ID',
          'NTQ4MDY1MjE1MDkz',
        ),
        projectId: _envOrFallback(
          'FIREBASE_PROJECT_ID',
          'cGFrZWFqYQ==',
        ),
        authDomain: _envOrFallback(
          'FIREBASE_WEB_AUTH_DOMAIN',
          'cGFrZWFqYS5maXJlYmFzZWFwcC5jb20=',
        ),
        storageBucket: _envOrFallback(
          'FIREBASE_STORAGE_BUCKET',
          'cGFrZWFqYS5maXJlYmFzZXN0b3JhZ2UuYXBw',
        ),
      );
}
