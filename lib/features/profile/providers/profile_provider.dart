import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart'
    show authStateProvider, sessionUserNameProvider, userDataProvider;
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

// ==================== USER STATS ====================
final userStatsProvider =
    Provider.autoDispose<AsyncValue<Map<String, int>>>((ref) {
  final clothesState = ref.watch(clothesListProvider);
  final favoritesState = ref.watch(favoriteOutfitsProvider);
  final historyState = ref.watch(outfitHistoryProvider);

  if (clothesState.isLoading ||
      favoritesState.isLoading ||
      historyState.isLoading) {
    return const AsyncValue.loading();
  }

  if (clothesState.hasError) {
    return AsyncValue.error(clothesState.error!, clothesState.stackTrace!);
  }

  final clothes = clothesState.valueOrNull ?? [];
  final favorites = favoritesState.valueOrNull ?? [];
  final history = historyState.valueOrNull ?? [];

  int wornCount = 0;
  for (final o in history) {
    wornCount += o.wornDates.length;
  }

  return AsyncValue.data({
    'totalClothes': clothes.length,
    'totalFavorites': favorites.length,
    'totalWorn': wornCount,
  });
});

// ==================== PROFILE UPDATE ====================
final updateProfileProvider =
    AsyncNotifierProvider<UpdateProfileNotifier, void>(UpdateProfileNotifier.new);

class UpdateProfileNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    state = const AsyncValue.loading();
    try {
      final result = await ref.read(authServiceProvider).updateProfile(
            name: trimmed,
          );
      if (!result.success) {
        // Fallback jika hanya Firestore repository yang di-override atau Auth belum sinkron
        final user = ref.read(authStateProvider).valueOrNull;
        if (user == null) {
          state = AsyncValue.error(
            result.message ?? 'Gagal memperbarui nama',
            StackTrace.current,
          );
          return false;
        }
        await ref.read(userRepositoryProvider).updateUser(
              uid: user.uid,
              data: {'name': trimmed},
            );
      }

      ref.read(sessionUserNameProvider.notifier).state = trimmed;
      ref.invalidate(userDataProvider);
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
