import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/firebase_options.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: '''
FIREBASE_PROJECT_ID=pakeaja
FIREBASE_MESSAGING_SENDER_ID=548065215093
FIREBASE_STORAGE_BUCKET=pakeaja.firebasestorage.app
FIREBASE_ANDROID_API_KEY=dummy-android-key
FIREBASE_ANDROID_APP_ID=1:548065215093:android:test
FIREBASE_IOS_API_KEY=dummy-ios-key
FIREBASE_IOS_APP_ID=1:548065215093:ios:test
FIREBASE_IOS_BUNDLE_ID=com.example.pakeaja
FIREBASE_WEB_API_KEY=dummy-web-key
FIREBASE_WEB_APP_ID=1:548065215093:web:a6471475a6691238106e3c
FIREBASE_WEB_AUTH_DOMAIN=pakeaja.firebaseapp.com
''',
    );
  });

  test('ErrorHandler formats permission-denied without AppException wrapper text', () {
    final firebaseError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
    );

    final wrapped = AppException(
      ErrorHandler.handle(firebaseError),
      code: firebaseError.code,
      originalError: firebaseError,
    );

    expect(wrapped.code, 'permission-denied');
    expect(
      ErrorHandler.handle(wrapped),
      'Kamu tidak memiliki izin untuk mengakses data ini.',
    );
    expect(ErrorHandler.handle(wrapped), isNot(contains('AppException:')));
    expect(ErrorHandler.handle(wrapped), isNot(contains('code: null')));
  });

  test('DefaultFirebaseOptions.web uses valid Firebase web configuration', () {
    expect(DefaultFirebaseOptions.web.projectId, 'pakeaja');
    expect(
      DefaultFirebaseOptions.web.appId,
      isNot(contains('000000000000000000000000')),
    );
    expect(DefaultFirebaseOptions.web.authDomain, 'pakeaja.firebaseapp.com');
  });
}

