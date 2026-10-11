import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';

class ClothRepository {
  final FirebaseFirestore _db;

  ClothRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference _clothesRef(String uid) =>
      _db.collection('users').doc(uid).collection('clothes');

  // ==================== STREAM ====================
  Stream<List<ClothModel>> watchClothes(String uid) {
    return _clothesRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) => throw Exception(ErrorHandler.handle(e)))
        .map((snapshot) =>
            snapshot.docs.map((doc) => ClothModel.fromFirestore(doc)).toList());
  }

  // Pagination
  Stream<List<ClothModel>> watchClothesPaged(
    String uid, {
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _clothesRef(uid).orderBy('createdAt', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => ClothModel.fromFirestore(d)).toList());
  }

  Stream<ClothModel?> watchCloth(String uid, String clothId) {
    return _clothesRef(uid).doc(clothId).snapshots().map((doc) =>
        doc.exists ? ClothModel.fromFirestore(doc) : null);
  }

  // ==================== CRUD ====================
  Future<ClothModel> addCloth({
    required String uid,
    required ClothModel cloth,
  }) async {
    try {
      final docRef = _clothesRef(uid).doc();
      final withId = cloth.copyWith();
      await docRef.set(withId.toFirestore()).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
                'Koneksi Firestore timeout. Pastikan Cloud Firestore sudah diaktifkan di Firebase Console.'),
          );
      final snapshot = await docRef.get().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Gagal mengambil data dari Firestore.'),
          );
      return ClothModel.fromFirestore(snapshot);
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  Future<void> updateCloth({
    required String uid,
    required String clothId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _clothesRef(uid).doc(clothId).update(data);
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  Future<void> deleteCloth({required String uid, required String clothId}) async {
    try {
      await _clothesRef(uid).doc(clothId).delete();
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  Future<void> updateWearStats({
    required String uid,
    required String clothId,
    required DateTime wornAt,
  }) async {
    try {
      await _clothesRef(uid).doc(clothId).update({
        'lastWornAt': Timestamp.fromDate(wornAt),
        'wearCount': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  // Gambar disimpan langsung sebagai Base64 di dokumen Firestore,
  // sehingga tidak membutuhkan operasi Storage terpisah.
  Future<void> deleteClothImage(String? imageUrl) async {
    // No-op: Data gambar otomatis terhapus bersama dokumen pakaian di Firestore.
  }
}

class OutfitRepository {
  final FirebaseFirestore _db;

  OutfitRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference _outfitsRef(String uid) =>
      _db.collection('users').doc(uid).collection('outfits');

  Stream<List<OutfitModel>> watchOutfits(String uid, {bool favoriteOnly = false}) {
    Query query = _outfitsRef(uid).orderBy('createdAt', descending: true);
    if (favoriteOnly) query = query.where('isFavorite', isEqualTo: true);
    return query
        .snapshots()
        .map((s) => s.docs.map((d) => OutfitModel.fromFirestore(d)).toList())
        .handleError((e) => throw Exception(ErrorHandler.handle(e)));
  }

  Stream<List<OutfitModel>> watchHistory(String uid) {
    return _outfitsRef(uid)
        .where('wornDates', isNotEqualTo: null)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OutfitModel.fromFirestore(d)).toList())
        .handleError((e) => throw Exception(ErrorHandler.handle(e)));
  }

  Future<OutfitModel> addOutfit({
    required String uid,
    required OutfitModel outfit,
  }) async {
    try {
      final docRef = _outfitsRef(uid).doc();
      await docRef.set(outfit.toFirestore());
      return OutfitModel.fromFirestore(await docRef.get());
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  Future<void> updateOutfit({
    required String uid,
    required String outfitId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _outfitsRef(uid).doc(outfitId).update(data);
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  Future<void> deleteOutfit({
    required String uid,
    required String outfitId,
  }) async {
    try {
      await _outfitsRef(uid).doc(outfitId).delete();
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  /// Mencatat outfit dipakai hari ini
  Future<void> markAsWorn({
    required String uid,
    required String outfitId,
    required DateTime wornAt,
  }) async {
    try {
      await _outfitsRef(uid).doc(outfitId).update({
        'wornDates': FieldValue.arrayUnion([Timestamp.fromDate(wornAt)]),
      });
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  Future<void> toggleFavorite({
    required String uid,
    required String outfitId,
    required bool value,
  }) async {
    try {
      await _outfitsRef(uid).doc(outfitId).update({'isFavorite': value});
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }
}
