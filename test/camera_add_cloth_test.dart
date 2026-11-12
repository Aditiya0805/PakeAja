import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/repositories/cloth_repository.dart';
import 'package:pakeaja/data/services/image_service.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class _FakeClothRepository implements ClothRepository {
  String? savedUid;
  ClothModel? savedCloth;

  @override
  Future<ClothModel> addCloth({
    required String uid,
    required ClothModel cloth,
  }) async {
    savedUid = uid;
    final withId = cloth.copyWith(id: 'cloth-cam-1');
    savedCloth = withId;
    return withId;
  }

  @override
  Future<void> deleteCloth({
    required String uid,
    required String clothId,
  }) async {}

  @override
  Future<void> deleteClothImage(String? imageUrl) async {}

  @override
  Future<void> updateCloth({
    required String uid,
    required String clothId,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<void> updateWearStats({
    required String uid,
    required String clothId,
    required DateTime wornAt,
  }) async {}

  @override
  Stream<ClothModel?> watchCloth(String uid, String clothId) =>
      Stream.value(null);

  @override
  Stream<List<ClothModel>> watchClothes(String uid) =>
      Stream.value(const []);

  @override
  Stream<List<ClothModel>> watchClothesPaged(
    String uid, {
    int limit = 30,
    DocumentSnapshot<Object?>? startAfter,
  }) =>
      Stream.value(const []);
}

class _TestCameraImageService extends ImageService {
  final Uint8List sampleBytes;

  _TestCameraImageService(this.sampleBytes);

  @override
  Future<ImagePickerResult> pickFromDeviceCamera(BuildContext context) async {
    return ImagePickerResult.ok(bytes: sampleBytes);
  }

  @override
  Future<String> compressAndConvertToBase64({
    File? image,
    Uint8List? bytes,
  }) async {
    final raw = bytes ?? sampleBytes;
    return super.compressAndConvertToBase64(bytes: raw);
  }
}

void main() {
  test('Camera capture bytes are saved to Firestore repository preserving schema', () async {
    final fakeRepo = _FakeClothRepository();
    final cameraBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);
    final fakeImageService = _TestCameraImageService(cameraBytes);

    final container = ProviderContainer(
      overrides: [
        clothRepositoryProvider.overrideWithValue(fakeRepo),
        imageServiceProvider.overrideWithValue(fakeImageService),
      ],
    );
    addTearDown(container.dispose);

    final cloth = ClothModel(
      id: '',
      name: 'Jersey Lari Biru',
      category: ClothCategory.top,
      color: ClothColor.blue,
      styles: const [ClothStyle.sport],
      weather: ClothWeather.hot,
      imageUrl: '',
      createdAt: DateTime(2026, 11, 12),
    );

    final ok = await container.read(addClothProvider.notifier).addCloth(
          uid: 'user-123',
          cloth: cloth,
          imageBytes: cameraBytes,
        );

    expect(ok, isTrue);
    expect(fakeRepo.savedUid, 'user-123');
    expect(fakeRepo.savedCloth, isNotNull);
    expect(fakeRepo.savedCloth!.name, 'Jersey Lari Biru');
    expect(fakeRepo.savedCloth!.styles, const [ClothStyle.sport]);
    expect(
      fakeRepo.savedCloth!.imageUrl.startsWith('data:image/jpeg;base64,'),
      isTrue,
    );

    final firestoreMap = fakeRepo.savedCloth!.toFirestore();
    expect(firestoreMap['name'], 'Jersey Lari Biru');
    expect(firestoreMap['category'], 'top');
    expect(firestoreMap['color'], 'blue');
    expect(firestoreMap['styles'], ['sport']);
    expect(firestoreMap['weather'], 'hot');
    expect(
      (firestoreMap['imageUrl'] as String).startsWith('data:image/jpeg;base64,'),
      isTrue,
    );
  });
}

