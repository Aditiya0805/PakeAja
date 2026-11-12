// File ini di-generate berdasarkan google-services.json project PakeAja.
// Project ID: pakeaja | Project Number: 548065215093

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBbH1pmRa6P6G8I6VOPNZdgbtDiyfjvZ4o',
    appId: '1:548065215093:android:9fc44bb9b04d953c106e3c',
    messagingSenderId: '548065215093',
    projectId: 'pakeaja',
    storageBucket: 'pakeaja.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDUBw4d_0pCeAAzz6UVzySAsaWN9W587O0',
    appId: '1:548065215093:ios:ebbafda2afc0477e106e3c',
    messagingSenderId: '548065215093',
    projectId: 'pakeaja',
    storageBucket: 'pakeaja.firebasestorage.app',
    iosBundleId: 'com.example.pakeaja',
  );

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCH156ZE1NltAmGrCYeqZDBnQ2lvJa9pKA',
    appId: '1:548065215093:web:a6471475a6691238106e3c',
    messagingSenderId: '548065215093',
    projectId: 'pakeaja',
    authDomain: 'pakeaja.firebaseapp.com',
    storageBucket: 'pakeaja.firebasestorage.app',
  );
}
