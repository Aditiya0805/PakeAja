import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/utils/auth_result.dart';
import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/data/models/user_model.dart';
import 'package:pakeaja/data/services/auth_service.dart';

// ==================== AUTH STATE ====================
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ==================== USER DATA ====================
final userDataProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);

  final sessionName = ref.watch(sessionUserNameProvider);
  return ref
      .watch(userRepositoryProvider)
      .watchUser(user.uid)
      .map((docUser) {
    if (docUser != null) {
      return docUser;
    }
    // Fallback otomatis dari data FirebaseAuth jika dokumen Firestore belum ada / sedang sync
    return UserModel.fromFirebaseUser(user, fallbackName: sessionName);
  });
});

/// Nama sementara di sesi aktif (diupdate langsung saat user input nama saat login/register/edit)
/// sehingga UI langsung mencerminkan nama yang diinputkan user sebelum maupun sesudah stream Firestore sinkron.
final sessionUserNameProvider = StateProvider<String?>((ref) => null);

/// Nama tampilan efektif user di seluruh aplikasi (Beranda, Profil, dll).
final effectiveUserNameProvider = Provider.autoDispose<String>((ref) {
  final sessionName = ref.watch(sessionUserNameProvider)?.trim();
  if (sessionName != null && sessionName.isNotEmpty) {
    return sessionName;
  }

  final userData = ref.watch(userDataProvider).valueOrNull;
  final docName = userData?.name.trim() ?? '';
  if (docName.isNotEmpty) return docName;

  final authUser = ref.watch(authStateProvider).valueOrNull;
  final authName = authUser?.displayName?.trim() ?? '';
  if (authName.isNotEmpty) return authName;

  final email = authUser?.email ?? userData?.email ?? '';
  if (email.contains('@')) {
    return email.split('@').first;
  }

  return 'Pengguna PakeAja';
});

// ==================== AUTH CONTROLLER ====================
class AuthController extends AsyncNotifier<void> {
  late final AuthService _auth;

  @override
  FutureOr<void> build() {
    _auth = ref.read(authServiceProvider);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final trimmedName = name.trim();
    try {
      final result = await _auth
          .register(
            name: trimmedName,
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 18),
            onTimeout: () => AuthResult.fail(
              'Koneksi timeout. Periksa jaringan internet kamu atau muat ulang halaman.',
            ),
          );
      if (result.success) {
        ref.read(sessionUserNameProvider.notifier).state =
            trimmedName.isNotEmpty ? trimmedName : null;
        ref.invalidate(userDataProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(
        result.message ?? 'Pendaftaran gagal.',
        StackTrace.current,
      );
      return false;
    } catch (e, st) {
      state = AsyncValue.error(
        ErrorHandler.handle(e),
        st,
      );
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    final trimmedName = name?.trim() ?? '';
    try {
      final result = await _auth
          .login(
            email: email,
            password: password,
            name: trimmedName.isNotEmpty ? trimmedName : null,
          )
          .timeout(
            const Duration(seconds: 18),
            onTimeout: () => AuthResult.fail(
              'Koneksi timeout. Periksa jaringan internet kamu atau muat ulang halaman.',
            ),
          );
      if (result.success) {
        ref.read(sessionUserNameProvider.notifier).state =
            trimmedName.isNotEmpty ? trimmedName : null;
        ref.invalidate(userDataProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(
        result.message ?? 'Gagal masuk.',
        StackTrace.current,
      );
      return false;
    } catch (e, st) {
      state = AsyncValue.error(
        ErrorHandler.handle(e),
        st,
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle({String? name}) async {
    state = const AsyncValue.loading();
    final trimmedName = name?.trim() ?? '';
    try {
      final result = await _auth
          .signInWithGoogle(
            name: trimmedName.isNotEmpty ? trimmedName : null,
          )
          .timeout(
            const Duration(seconds: 70),
            onTimeout: () => AuthResult.fail(
              'Waktu masuk Google habis. Silakan coba lagi.',
            ),
          );
      if (result.success) {
        ref.read(sessionUserNameProvider.notifier).state =
            trimmedName.isNotEmpty ? trimmedName : null;
        ref.invalidate(userDataProvider);
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(
        result.message ?? 'Gagal masuk dengan Google.',
        StackTrace.current,
      );
      return false;
    } catch (e, st) {
      state = AsyncValue.error(
        ErrorHandler.handle(e),
        st,
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      final result = await _auth
          .sendPasswordResetEmail(email)
          .timeout(
            const Duration(seconds: 18),
            onTimeout: () => AuthResult.fail(
              'Koneksi timeout saat mengirim email reset password.',
            ),
          );
      if (result.success) {
        state = const AsyncValue.data(null);
        return true;
      }
      state = AsyncValue.error(
        result.message ?? 'Gagal mengirim email reset.',
        StackTrace.current,
      );
      return false;
    } catch (e, st) {
      state = AsyncValue.error(
        ErrorHandler.handle(e),
        st,
      );
      return false;
    }
  }

  Future<bool> logout() async {
    final result = await _auth.logout();
    if (result.success) {
      ref.read(sessionUserNameProvider.notifier).state = null;
    }
    return result.success;
  }

  Future<bool> deleteAccount(String password) async {
    final result = await _auth.deleteAccount(password);
    if (result.success) {
      ref.read(sessionUserNameProvider.notifier).state = null;
    }
    return result.success;
  }

  Future<bool> updateProfile({String? name}) async {
    final trimmedName = name?.trim();
    final result = await _auth.updateProfile(name: trimmedName);
    if (result.success && trimmedName != null && trimmedName.isNotEmpty) {
      ref.read(sessionUserNameProvider.notifier).state = trimmedName;
      ref.invalidate(userDataProvider);
    }
    return result.success;
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

// Error message helper
String? authErrorMessage(AsyncValue<void> state) {
  if (state.isLoading) return null;
  final err = state.error;
  if (err == null) return null;
  return err.toString().replaceFirst('Exception: ', '');
}
