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
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(clothesListProvider).valueOrNull ?? [];
});

// ==================== RECOMMENDATION STATE ====================
class RecommendationState {
  final bool isLoading;
  final String selectedOccasion;
  final OutfitRecommendation? recommendation;
  final String? error;

  const RecommendationState({
    this.isLoading = false,
    this.selectedOccasion = 'Kuliah',
    this.recommendation,
    this.error,
  });

  RecommendationState copyWith({
    bool? isLoading,
    String? selectedOccasion,
    OutfitRecommendation? recommendation,
    bool clearRecommendation = false,
    String? error,
  }) {
    return RecommendationState(
      isLoading: isLoading ?? this.isLoading,
      selectedOccasion: selectedOccasion ?? this.selectedOccasion,
      recommendation:
          clearRecommendation ? null : (recommendation ?? this.recommendation),
      error: error,
    );
  }
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier,
    RecommendationState>((ref) => RecommendationNotifier(ref));

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final Ref _ref;
  String _currentOccasion = 'Kuliah';

  RecommendationNotifier(this._ref) : super(const RecommendationState()) {
    // Dengarkan perubahan pada daftar pakaian untuk rekomendasi secara reaktif
    _ref.listen<List<ClothModel>>(clothesForRecommendationProvider, (prev, next) {
      if (next.isNotEmpty) {
        // Jika belum ada rekomendasi (atau error sebelumnya setelah lemari berubah)
        if (state.recommendation == null || state.error == 'Belum cukup') {
          recommend(_currentOccasion);
        } else {
          // Atau jika ada item rekomendasi saat ini yang sudah tidak ada lagi di lemari (misal dihapus)
          final currentIds = state.recommendation!.itemIds;
          final nextIds = next.map((c) => c.id).toSet();
          if (!currentIds.every((id) => nextIds.contains(id))) {
            recommend(_currentOccasion);
          }
        }
      }
    });
  }

  Future<void> recommend(String occasion) async {
    _currentOccasion = occasion;
    state = state.copyWith(
      isLoading: true,
      selectedOccasion: occasion,
      clearRecommendation: true,
      error: null,
    );
    try {
      final clothes = _ref.read(clothesForRecommendationProvider);
      final service = _ref.read(recommendationServiceProvider);

      // Cek kelengkapan umum
      if (!service.canRecommend(clothes)) {
        state = state.copyWith(
          isLoading: false,
          selectedOccasion: occasion,
          clearRecommendation: true,
          error: 'Belum cukup',
        );
        return;
      }

      // Ambil excluded IDs dari riwayat agar berbeda
      final history = _ref.read(outfitHistoryProvider).valueOrNull ?? [];
      final recentIds = <String>{};
      for (final o in history.take(3)) {
        recentIds.addAll(o.itemIds);
      }

      final result = service.recommend(
        clothes: clothes,
        occasion: occasion,
        excludedIds: recentIds.toList(),
      );

      state = RecommendationState(
        selectedOccasion: occasion,
        recommendation: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        selectedOccasion: occasion,
        clearRecommendation: true,
        error: ErrorHandler.handle(e),
      );
    }
  }

  /// Acak ulang: rekomendasi alternatif
  Future<void> reshuffle(String occasion) async {
    _currentOccasion = occasion;
    final current = state.recommendation;
    if (current == null) {
      return recommend(occasion);
    }

    state = state.copyWith(
      isLoading: true,
      selectedOccasion: occasion,
      error: null,
    );
    try {
      final clothes = _ref.read(clothesForRecommendationProvider);
      final service = _ref.read(recommendationServiceProvider);

      if (!service.canRecommend(clothes)) {
        state = state.copyWith(
          isLoading: false,
          selectedOccasion: occasion,
          clearRecommendation: true,
          error: 'Belum cukup',
        );
        return;
      }

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

      state = RecommendationState(
        selectedOccasion: occasion,
        recommendation: result,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        selectedOccasion: occasion,
        clearRecommendation: true,
        error: ErrorHandler.handle(e),
      );
    }
  }

  void reset() => state = const RecommendationState();
}
