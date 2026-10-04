
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pakeaja/core/utils/error_handler.dart';
import 'package:pakeaja/data/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<UserModel?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) =>
        doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  Future<void> updateUser({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }

  // ==================== STATS ====================
  Future<Map<String, int>> getStats(String uid) async {
    try {
      final clothes =
          await _db.collection('users').doc(uid).collection('clothes').get();
      final outfits =
          await _db.collection('users').doc(uid).collection('outfits').get();

      int favCount = 0;
      int wornCount = 0;
      for (final doc in outfits.docs) {
        final data = doc.data();
        if (data['isFavorite'] == true) favCount++;
        final worn = data['wornDates'] as List<dynamic>?;
        if (worn != null && worn.isNotEmpty) wornCount++;
      }

      return {
        'totalClothes': clothes.docs.length,
        'totalFavorites': favCount,
        'totalWorn': wornCount,
      };
    } on Exception catch (e) {
      throw Exception(ErrorHandler.handle(e));
    }
  }
}

/// Helper untuk cek koneksi internet
class ConnectivityService {
  /// Implementasi ringan tanpa package connectivity_plus
  /// Coba fetch kecil ke Firestore untuk cek koneksi
  Future<bool> isOnline() async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .limit(1)
          .get();
      return result.size >= 0;
    } on Exception catch (_) {
      return false;
    }
  }
}
