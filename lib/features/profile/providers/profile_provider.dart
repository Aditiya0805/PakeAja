import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart'
    show authStateProvider;

// ==================== PROFILE UPDATE ====================
final updateProfileProvider =
    AsyncNotifierProvider<UpdateProfileNotifier, void>(UpdateProfileNotifier.new);

class UpdateProfileNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateName(String name) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return false;

      await ref.read(userRepositoryProvider).updateUser(
            uid: user.uid,
            data: {'name': name.trim()},
          );
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (e) {
      state = AsyncValue.error(ErrorHandler.handle(e), StackTrace.current);
      return false;
    }
  }
}

// ==================== CONNECTIVITY ====================
/// Cek koneksi internet dengan ping ke Firestore
final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield* Stream.periodic(const Duration(seconds: 10), (_) => null)
      .asyncMap((_) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .limit(1)
          .get();
      return true;
    } on Exception catch (_) {
      return false;
    }
  });
});
