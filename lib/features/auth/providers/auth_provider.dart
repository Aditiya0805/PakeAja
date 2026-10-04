import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/data/models/user_model.dart';
import 'package:pakeaja/data/repositories/user_repository.dart';
import 'package:pakeaja/data/services/auth_service.dart';

// ==================== AUTH STATE ====================
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ==================== USER DATA ====================
final userDataProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
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
    final result = await _auth.register(
      name: name,
      email: email,
      password: password,
    );
    if (result.success) {
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message ?? 'Gagal', StackTrace.current);
    return false;
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await _auth.login(email: email, password: password);
    if (result.success) {
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message ?? 'Gagal', StackTrace.current);
    return false;
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _auth.signInWithGoogle();
    if (result.success) {
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message ?? 'Gagal', StackTrace.current);
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    final result = await _auth.sendPasswordResetEmail(email);
    if (result.success) {
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message ?? 'Gagal', StackTrace.current);
    return false;
  }

  Future<bool> logout() async {
    final result = await _auth.logout();
    return result.success;
  }

  Future<bool> deleteAccount(String password) async {
    final result = await _auth.deleteAccount(password);
    return result.success;
  }

  Future<bool> updateProfile({String? name}) async {
    final result = await _auth.updateProfile(name: name);
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
