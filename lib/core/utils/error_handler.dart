import 'dart:async';
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

    final msg = error?.toString() ?? '';
    if (msg.contains('firestore.googleapis.com') ||
        (msg.contains('PERMISSION_DENIED') && msg.contains('Cloud Firestore API'))) {
      return 'Cloud Firestore API belum diaktifkan di Firebase Console. Silakan aktifkan Firestore Database di Firebase Console.';
    }

    if (error is TimeoutException || msg.contains('timeout') || msg.contains('TimeoutException')) {
      return 'Koneksi ke Firebase timeout. Periksa internet atau muat ulang halaman.';
    }

    // Network / connection errors - khusus jika benar-benar SocketException atau lookup gagal
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'Koneksi internet tidak tersedia. Periksa jaringan kamu.';
    }

    // Tangani kemungkinan error storage/interop WebKit di browser
    if (msg.contains('Null check operator') || msg.contains('_NullCheck')) {
      return 'Gagal terhubung ke akun. Silakan coba masuk kembali.';
    }

    if (msg.startsWith('Exception: ')) {
      final clean = msg.substring(11).trim();
      if (clean.isNotEmpty) return clean;
    }

    if (kDebugMode) {
      debugPrint('Unhandled error: $error');
    }
    if (msg.isNotEmpty && !msg.startsWith('Instance of')) {
      return msg;
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan. Cek email kamu.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'invalid-login-credentials':
        return 'Email atau password salah. Silakan periksa kembali.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'user-disabled':
        return 'Akun kamu telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'operation-not-allowed':
        return 'Metode login Google belum diaktifkan di Firebase Console (Sign-in provider Google belum aktif).';
      case 'unauthorized-domain':
        return 'Domain website ini belum ditambahkan ke Authorized Domains di Firebase Console.';
      case 'popup-blocked':
        return 'Jendela pop-up login Google diblokir oleh browser. Izinkan pop-up untuk melanjutkan.';
      case 'requires-recent-login':
        return 'Silakan login kembali untuk melanjutkan.';
      case 'credential-already-in-use':
        return 'Akun Google sudah terdaftar dengan cara lain.';
      case 'network-request-failed':
        return 'Gagal terhubung ke server autentikasi. Pastikan koneksi internet aktif.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Login Google dibatalkan.';
      default:
        final m = e.message;
        if (m != null && m.isNotEmpty) {
          return m;
        }
        return 'Gagal autentikasi (${e.code}). Silakan coba lagi.';
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
