import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart'
    show authStateProvider;

// ==================== CLOTHES LIST ====================
final clothesListProvider = StreamProvider.autoDispose<List<ClothModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(clothRepositoryProvider).watchClothes(user.uid);
});

// ==================== FILTER STATE ====================
class ClothFilter {
  final String category; // 'all' atau category value
  final String color;
  final String style;
  final String search;

  const ClothFilter({
    this.category = 'all',
    this.color = 'all',
    this.style = 'all',
    this.search = '',
  });

  ClothFilter copyWith({
    String? category,
    String? color,
    String? style,
    String? search,
  }) {
    return ClothFilter(
      category: category ?? this.category,
      color: color ?? this.color,
      style: style ?? this.style,
      search: search ?? this.search,
    );
  }

  bool matches(ClothModel cloth) {
    if (category != 'all' && cloth.category.value != category) return false;
    if (color != 'all' && cloth.color != color) return false;
    if (style != 'all' && !cloth.styles.any((s) => s.value == style)) {
      return false;
    }
    if (search.isNotEmpty &&
        !cloth.name.toLowerCase().contains(search.toLowerCase())) {
      return false;
    }
    return true;
  }

  bool get isActive =>
      category != 'all' || color != 'all' || style != 'all' || search.isNotEmpty;
}

final clothFilterProvider =
    StateProvider<ClothFilter>((ref) => const ClothFilter());

final filteredClothesProvider =
    Provider.autoDispose<List<ClothModel>>((ref) {
  final clothes = ref.watch(clothesListProvider).value ?? [];
  final filter = ref.watch(clothFilterProvider);
  return clothes.where(filter.matches).toList();
});

// ==================== ADD CLOTH ====================
class AddClothState {
  final bool isLoading;
  final String? error;
  final bool success;

  const AddClothState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  AddClothState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return AddClothState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

final addClothProvider =
    StateNotifierProvider<AddClothNotifier, AddClothState>(
        (ref) => AddClothNotifier(ref));

class AddClothNotifier extends StateNotifier<AddClothState> {
  final Ref _ref;
  AddClothNotifier(this._ref) : super(const AddClothState());

  Future<bool> addCloth({
    required String uid,
    required ClothModel cloth,
    required File image,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(clothRepositoryProvider);
      final imageService = _ref.read(imageServiceProvider);

      // 1. Compress
      final compressed = await imageService.compressImage(image);

      // 2. Simpan metadata dulu untuk dapat clothId
      final saved = await repo.addCloth(uid: uid, cloth: cloth);

      // 3. Upload image
      final imageUrl = await repo.uploadClothImage(
        uid: uid,
        clothId: saved.id,
        image: compressed,
      );

      // 4. Update URL di Firestore
      await repo.updateCloth(
        uid: uid,
        clothId: saved.id,
        data: {'imageUrl': imageUrl},
      );

      state = const AddClothState(success: true);
      return true;
    } on Exception catch (e) {
      state = AddClothState(error: ErrorHandler.handle(e));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() => state = const AddClothState();
}

// ==================== UPDATE CLOTH ====================
final updateClothProvider =
    AsyncNotifierProvider<UpdateClothNotifier, void>(UpdateClothNotifier.new);

class UpdateClothNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateCloth({
    required String uid,
    required String clothId,
    required Map<String, dynamic> data,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(clothRepositoryProvider).updateCloth(
            uid: uid,
            clothId: clothId,
            data: data,
          );
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (e) {
      state = AsyncValue.error(ErrorHandler.handle(e), StackTrace.current);
      return false;
    }
  }
}

// ==================== DELETE CLOTH ====================
final deleteClothProvider =
    AsyncNotifierProvider<DeleteClothNotifier, void>(DeleteClothNotifier.new);

class DeleteClothNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> deleteCloth({
    required String uid,
    required String clothId,
    required String? imageUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(clothRepositoryProvider);
      await repo.deleteCloth(uid: uid, clothId: clothId);
      if (imageUrl != null) {
        await repo.deleteClothImage(imageUrl); // best effort
      }
      state = const AsyncValue.data(null);
      return true;
    } on Exception catch (e) {
      state = AsyncValue.error(ErrorHandler.handle(e), StackTrace.current);
      return false;
    }
  }
}
