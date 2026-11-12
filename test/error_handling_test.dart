import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/firebase_options.dart';

void main() {
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

