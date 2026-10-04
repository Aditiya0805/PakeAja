import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart' show authStateProvider;
import '../../outfits/providers/outfit_provider.dart'
    show outfitHistoryProvider;
import '../../wardrobe/providers/wardrobe_provider.dart'
    show clothesListProvider;

// ==================== CLOTHES FOR RECOMMENDATION ====================
final clothesForRecommendationProvider =
    Provider.autoDispose<List<ClothModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];
  return ref.watch(clothesListProvider).value ?? [];
});

// ==================== RECOMMENDATION STATE ====================
class RecommendationState {
  final bool isLoading;
  final OutfitRecommendation? recommendation;
  final String? error;

  const RecommendationState({
    this.isLoading = false,
    this.recommendation,
    this.error,
  });

  RecommendationState copyWith({
    bool? isLoading,
    OutfitRecommendation? recommendation,
    String? error,
  }) {
    return RecommendationState(
      isLoading: isLoading ?? this.isLoading,
      recommendation: recommendation ?? this.recommendation,
      error: error,
    );
  }
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier,
    RecommendationState>((ref) => RecommendationNotifier(ref));

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final Ref _ref;
  RecommendationNotifier(this._ref) : super(const RecommendationState());

  Future<void> recommend(String occasion) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final clothes = _ref.read(clothesForRecommendationProvider);
      final service = _ref.read(recommendationServiceProvider);

      // Cek kelengkapan
      if (!service.canRecommend(clothes)) {
        state = state.copyWith(isLoading: false, error: 'Belum cukup');
        return;
      }

      // Ambil excluded IDs dari riwayat agar berbeda
      final history = _ref.read(outfitHistoryProvider).value ?? [];
      final recentIds = <String>{};
      for (final o in history.take(3)) {
        recentIds.addAll(o.itemIds);
      }

      final result = service.recommend(
        clothes: clothes,
        occasion: occasion,
        excludedIds: recentIds.toList(),
      );

      state = RecommendationState(recommendation: result);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHandler.handle(e));
    }
  }

  /// Acak ulang: rekomendasi alternatif
  Future<void> reshuffle(String occasion) async {
    final current = state.recommendation;
    if (current == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final clothes = _ref.read(clothesForRecommendationProvider);
      final service = _ref.read(recommendationServiceProvider);

      final excluded = <String>[...current.itemIds];

      OutfitRecommendation? result;
      var attempts = 0;
      while (attempts < 5) {
        try {
          final candidate = service.recommend(
            clothes: clothes,
            occasion: occasion,
            excludedIds: excluded,
          );
          if (candidate.itemIds.join() != current.itemIds.join()) {
            result = candidate;
            break;
          }
        } on Exception catch (_) {
          // coba lagi
        }
        attempts++;
      }

      result ??= service.recommend(clothes: clothes, occasion: occasion);

      state = RecommendationState(recommendation: result);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHandler.handle(e));
    }
  }

  void reset() => state = const RecommendationState();
}
