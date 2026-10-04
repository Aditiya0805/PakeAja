import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/data/repositories/cloth_repository.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart'
    show authStateProvider;

final outfitRepositoryProvider =
    Provider<OutfitRepository>((ref) => OutfitRepository());

// ==================== FAVORITES ====================
final favoriteOutfitsProvider =
    StreamProvider.autoDispose<List<OutfitModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .watch(outfitRepositoryProvider)
      .watchOutfits(user.uid, favoriteOnly: true);
});

// ==================== HISTORY ====================
final outfitHistoryProvider =
    StreamProvider.autoDispose<List<OutfitModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(outfitRepositoryProvider).watchHistory(user.uid);
});

// ==================== SAVE OUTFIT ====================
final saveOutfitProvider =
    AsyncNotifierProvider<SaveOutfitNotifier, OutfitModel?>(
        SaveOutfitNotifier.new);

class SaveOutfitNotifier extends AsyncNotifier<OutfitModel?> {
  @override
  FutureOr<OutfitModel?> build() => null;

  /// Simpan outfit sebagai favorite
  Future<bool> saveOutfit({
    required List<String> itemIds,
    required String occasion,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        state = AsyncValue.error('Kamu belum login', StackTrace.current);
        return false;
      }

      final outfit = OutfitModel(
        id: '',
        itemIds: itemIds,
        occasion: occasion,
        isFavorite: true,
        wornDates: const [],
        createdAt: DateTime.now(),
      );

      final saved = await ref
          .read(outfitRepositoryProvider)
          .addOutfit(uid: user.uid, outfit: outfit);

      state = AsyncValue.data(saved);
      return true;
    } on Exception catch (e) {
      state = AsyncValue.error(ErrorHandler.handle(e), StackTrace.current);
      return false;
    }
  }
}

// ==================== WEAR OUTFIT ====================
final wearOutfitProvider =
    AsyncNotifierProvider<WearOutfitNotifier, void>(WearOutfitNotifier.new);

class WearOutfitNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Mencatat outfit dipakai hari ini + update stats pakaian
  Future<bool> wearOutfit({
    required List<String> itemIds,
    required String occasion,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        state = AsyncValue.error('Kamu belum login', StackTrace.current);
        return false;
      }

      final now = DateTime.now();
      final outfitRepo = ref.read(outfitRepositoryProvider);
      final clothRepo = ref.read(clothRepositoryProvider);

      final outfit = OutfitModel(
        id: '',
        itemIds: itemIds,
        occasion: occasion,
        isFavorite: false,
        wornDates: [now],
        createdAt: now,
      );

      await outfitRepo.addOutfit(uid: user.uid, outfit: outfit);

      // Update wear stats untuk setiap item
      for (final itemId in itemIds) {
        await clothRepo.updateWearStats(
          uid: user.uid,
          clothId: itemId,
          wornAt: now,
        );
      }

      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (e) {
      state = AsyncValue.error(ErrorHandler.handle(e), StackTrace.current);
      return false;
    }
  }
}

// ==================== TOGGLE FAVORITE ====================
final toggleFavoriteProvider =
    AsyncNotifierProvider<ToggleFavoriteNotifier, void>(
        ToggleFavoriteNotifier.new);

class ToggleFavoriteNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> toggle({
    required String outfitId,
    required bool value,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return false;

      await ref.read(outfitRepositoryProvider).toggleFavorite(
            uid: user.uid,
            outfitId: outfitId,
            value: value,
          );
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (e) {
      state = AsyncValue.error(ErrorHandler.handle(e), StackTrace.current);
      return false;
    }
  }
}

// ==================== DELETE OUTFIT ====================
final deleteOutfitProvider =
    AsyncNotifierProvider<DeleteOutfitNotifier, void>(DeleteOutfitNotifier.new);

class DeleteOutfitNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> deleteOutfit({required String outfitId}) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return false;

      await ref
          .read(outfitRepositoryProvider)
          .deleteOutfit(uid: user.uid, outfitId: outfitId);
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (e) {
      state = AsyncValue.error(ErrorHandler.handle(e), StackTrace.current);
      return false;
    }
  }
}

// ==================== STATS ====================
final userStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return {'totalClothes': 0, 'totalFavorites': 0, 'totalWorn': 0};
  }
  return ref.read(userRepositoryProvider).getStats(user.uid);
});
