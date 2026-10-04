import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitModel {
  final String id;
  final List<String> itemIds;
  final String occasion;
  final bool isFavorite;
  final List<DateTime> wornDates;
  final DateTime createdAt;

  const OutfitModel({
    required this.id,
    required this.itemIds,
    required this.occasion,
    this.isFavorite = false,
    this.wornDates = const [],
    required this.createdAt,
  });

  factory OutfitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OutfitModel(
      id: doc.id,
      itemIds: (data['itemIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      occasion: data['occasion'] as String? ?? '',
      isFavorite: data['isFavorite'] as bool? ?? false,
      wornDates: (data['wornDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'itemIds': itemIds,
        'occasion': occasion,
        'isFavorite': isFavorite,
        'wornDates': wornDates.map((d) => Timestamp.fromDate(d)).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  OutfitModel copyWith({
    List<String>? itemIds,
    String? occasion,
    bool? isFavorite,
    List<DateTime>? wornDates,
    DateTime? createdAt,
  }) {
    return OutfitModel(
      id: id,
      itemIds: itemIds ?? this.itemIds,
      occasion: occasion ?? this.occasion,
      isFavorite: isFavorite ?? this.isFavorite,
      wornDates: wornDates ?? this.wornDates,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Hasil rekomendasi outfit yang sudah dihitung score-nya.
/// Bukan disimpan di Firestore kecuali user simpan/pakai.
class OutfitRecommendation {
  final String id;
  final List<String> itemIds;
  final String occasion;
  final double score;
  final List<ClothScoreDetail> details;

  const OutfitRecommendation({
    required this.id,
    required this.itemIds,
    required this.occasion,
    required this.score,
    this.details = const [],
  });
}

class ClothScoreDetail {
  final String clothId;
  final String clothName;
  final double score;
  final String reason;

  const ClothScoreDetail({
    required this.clothId,
    required this.clothName,
    required this.score,
    this.reason = '',
  });
}
