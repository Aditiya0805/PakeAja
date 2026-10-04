import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class ErrorHandler {
  static String handle(dynamic error) {
    if (error is AppException) return error.message;

    if (error is FirebaseAuthException) return _handleAuthError(error);
    if (error is FirebaseException) return _handleFirebaseError(error);

    // Network / connection errors
    final msg = error?.toString() ?? '';
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('SocketException') ||
        msg.contains('no internet')) {
      return 'Koneksi internet tidak tersedia. Periksa jaringan kamu.';
    }

    if (kDebugMode) {
      debugPrint('Unhandled error: $error');
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan. Cek email kamu.';
      case 'wrong-password':
        return 'Password salah. Coba lagi.';
      case 'invalid-email':
        return 'Email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'user-disabled':
        return 'Akun kamu telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'operation-not-allowed':
        return 'Metode login tidak diizinkan.';
      case 'requires-recent-login':
        return 'Silakan login kembali untuk melanjutkan.';
      case 'credential-already-in-use':
        return 'Akun Google sudah terdaftar dengan cara lain.';
      default:
        return 'Gagal masuk. Silakan coba lagi.';
    }
  }

  static String _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'Layanan tidak tersedia. Coba lagi nanti.';
      case 'unauthenticated':
        return 'Silakan login kembali.';
      case 'permission-denied':
        return 'Kamu tidak memiliki izin untuk mengakses data ini.';
      case 'not-found':
        return 'Data tidak ditemukan.';
      case 'object-not-found':
        return 'File tidak ditemukan.';
      case 'resource-exhausted':
        return 'Kuota terlampaui. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
