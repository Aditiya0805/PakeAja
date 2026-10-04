import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';

/// Rule-based outfit recommendation engine (MVP, tanpa ML)
/// Sesuai PRD: scoring berdasarkan occasion, warna, sepatu, rotasi pemakaian.
class RecommendationService {
  // Bobot scoring
  static const double wOccasion = 40.0;
  static const double wColor = 25.0;
  static const double wShoe = 15.0;
  static const double wRotation = 20.0;

  // Warna netral (mudah dipadukan)
  static const List<String> _neutral = ['black', 'white', 'gray', 'navy', 'cream'];

  // Warna analogus (harmonis)
  static const Map<String, List<String>> _analogous = {
    'black': ['white', 'gray', 'navy', 'brown'],
    'white': ['black', 'gray', 'navy', 'blue', 'cream'],
    'gray': ['black', 'white', 'navy', 'blue'],
    'navy': ['white', 'gray', 'blue', 'brown', 'cream'],
    'blue': ['white', 'gray', 'navy'],
    'red': ['white', 'black', 'navy'],
    'green': ['white', 'brown', 'cream'],
    'brown': ['cream', 'white', 'navy', 'green'],
    'cream': ['brown', 'navy', 'white'],
    'other': ['black', 'white', 'gray', 'navy'],
  };

  /// Map sepatu yang cocok untuk tiap gaya (berdasarkan nama pakaian)
  static const Map<String, List<String>> _shoeKeywords = {
    'formal': ['loafers', 'pantofel', 'sepatu formal', 'oxford', 'derby'],
    'casual': ['sneakers', 'canvas', 'sepatu casual', 'slip on'],
    'sport': ['running', 'sport', 'sneakers'],
  };

  /// Mengecek apakah user punya cukup item untuk rekomendasi
  bool canRecommend(List<ClothModel> clothes) {
    final tops = clothes.where((c) => c.category == ClothCategory.top).length;
    final bottoms =
        clothes.where((c) => c.category == ClothCategory.bottom).length;
    final onepieces =
        clothes.where((c) => c.category == ClothCategory.onepiece).length;
    final shoes = clothes.where((c) => c.category == ClothCategory.shoes).length;

    // (1 top + 1 bottom + 1 shoes) ATAU (1 onepiece + 1 shoes)
    return (tops >= 1 && bottoms >= 1 && shoes >= 1) ||
        (onepieces >= 1 && shoes >= 1);
  }

  /// Kembalikan checklist yang belum terpenuhi
  Map<String, bool> missingItems(List<ClothModel> clothes) {
    final hasTop = clothes.any((c) => c.category == ClothCategory.top);
    final hasBottom = clothes.any((c) => c.category == ClothCategory.bottom);
    final hasShoes = clothes.any((c) => c.category == ClothCategory.shoes);
    final hasOnepiece =
        clothes.any((c) => c.category == ClothCategory.onepiece);

    final enough = canRecommend(clothes);
    return {
      'top': hasTop || hasOnepiece,
      'bottom': hasBottom || hasOnepiece,
      'shoes': hasShoes,
      'enough': enough,
    };
  }

  /// Generate rekomendasi outfit.
  /// [excludedIds] dipakai untuk "Acak Ulang" agar tidak sama.
  OutfitRecommendation recommend({
    required List<ClothModel> clothes,
    required String occasion,
    List<String> excludedIds = const [],
  }) {
    // Filter item yang sudah pernah diexclude
    final pool = clothes.where((c) => !excludedIds.contains(c.id)).toList();

    final occasionStyles = _occasionStyles(occasion);

    // Pilih kandidat per kategori
    final top = _pickBest(pool, ClothCategory.top, occasionStyles, occasion);
    final bottom =
        _pickBest(pool, ClothCategory.bottom, occasionStyles, occasion);
    final shoes = _pickBest(pool, ClothCategory.shoes, occasionStyles, occasion);
    final outer = _pickOptional(pool, ClothCategory.outer, occasionStyles);
    final accessory =
        _pickOptional(pool, ClothCategory.accessory, occasionStyles);

    // Fallback: kalau top/bottom kosong, coba one-piece
    ClothModel? onepiece;
    if (top == null && bottom == null) {
      onepiece = _pickBest(pool, ClothCategory.onepiece, occasionStyles, occasion);
    }

    final itemIds = <String>[
      if (onepiece != null) onepiece.id else ...[if (top != null) top.id, if (bottom != null) bottom.id],
      if (shoes != null) shoes.id,
      if (outer != null) outer.id,
      if (accessory != null) accessory.id,
    ];

    if (itemIds.isEmpty) {
      throw Exception('Belum ada pakaian yang cukup untuk rekomendasi.');
    }

    // Hitung score per item
    final details = <ClothScoreDetail>[];
    double total = 0;
    for (final id in itemIds) {
      final cloth = pool.firstWhere((c) => c.id == id, orElse: () => pool.first);
      final s = _scoreItem(
        cloth: cloth,
        occasionStyles: occasionStyles,
        otherColors: itemIds
            .where((e) => e != id)
            .map((e) => pool.firstWhere((c) => c.id == e, orElse: () => cloth).color)
            .toList(),
        occasion: occasion,
      );
      details.add(ClothScoreDetail(
        clothId: cloth.id,
        clothName: cloth.name,
        score: s,
      ));
      total += s;
    }

    final avgScore = total / itemIds.length;

    return OutfitRecommendation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemIds: itemIds,
      occasion: occasion,
      score: avgScore,
      details: details,
    );
  }

  List<String> _occasionStyles(String occasion) {
    const map = {
      'Kuliah': ['casual', 'semi-formal'],
      'Santai': ['casual'],
      'Formal': ['formal', 'semi-formal'],
      'Semi Formal': ['semi-formal', 'casual'],
      'Olahraga': ['sport'],
      'Organisasi': ['formal', 'semi-formal'],
      'Lainnya': ['casual', 'semi-formal', 'formal'],
    };
    return map[occasion] ?? ['casual'];
  }

  /// Pilih item terbaik untuk kategori wajib
  ClothModel? _pickBest(
    List<ClothModel> pool,
    ClothCategory category,
    List<String> occasionStyles,
    String occasion,
  ) {
    final candidates = pool.where((c) => c.category == category).toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final sa = _scoreItem(
        cloth: a,
        occasionStyles: occasionStyles,
        otherColors: [],
        occasion: occasion,
      );
      final sb = _scoreItem(
        cloth: b,
        occasionStyles: occasionStyles,
        otherColors: [],
        occasion: occasion,
      );
      return sb.compareTo(sa);
    });
    return candidates.first;
  }

  /// Pilih item opsional (outer/aksesori), hanya kalau cocok
  ClothModel? _pickOptional(
    List<ClothModel> pool,
    ClothCategory category,
    List<String> occasionStyles,
  ) {
    final candidates = pool.where((c) => c.category == category).toList();
    if (candidates.isEmpty) return null;

    // Ambil yang style-nya cocok
    final matching = candidates
        .where((c) => c.styles.any((s) => occasionStyles.contains(s.value)))
        .toList();
    if (matching.isEmpty) return null; // Tidak wajib

    // Random agar bervariasi
    matching.shuffle();
    return matching.first;
  }

  double _scoreItem({
    required ClothModel cloth,
    required List<String> occasionStyles,
    required List<String> otherColors,
    required String occasion,
  }) {
    double score = 0;

    // A. Kesesuaian acara (40)
    final styleMatch = cloth.styles.any((s) => occasionStyles.contains(s.value));
    if (styleMatch) {
      score += wOccasion;
    } else {
      // Style tidak cocok: penalty besar
      score += 5;
    }

    // B. Kesesuaian warna (25)
    score += _colorScore(cloth.color, otherColors);

    // C. Kesesuaian sepatu (15) - hanya untuk sepatu
    if (cloth.category == ClothCategory.shoes) {
      score += _shoeScore(cloth, occasionStyles);
    } else {
      score += wShoe; // item non-sepatu dapat full
    }

    // D. Rotasi pakaian (20)
    score += _rotationScore(cloth);

    return score;
  }

  double _colorScore(String color, List<String> otherColors) {
    if (otherColors.isEmpty) {
      return _neutral.contains(color) ? wColor : wColor * 0.7;
    }

    // Cek apakah warna cocok dengan warna item lain
    double totalMatch = 0;
    for (final other in otherColors) {
      if (color == other) {
        totalMatch += 0.5; // warna sama: netral
      } else if (_neutral.contains(color) || _neutral.contains(other)) {
        totalMatch += 1.0; // netral cocok dengan apa saja
      } else if (_analogous[color]?.contains(other) ?? false) {
        totalMatch += 1.0; // analogus
      } else {
        totalMatch += 0.2; // komplementer kurang cocok
      }
    }

    return wColor * (totalMatch / otherColors.length);
  }

  double _shoeScore(ClothModel shoe, List<String> occasionStyles) {
    final name = shoe.name.toLowerCase();
    for (final style in occasionStyles) {
      final keywords = _shoeKeywords[style] ?? [];
      for (final kw in keywords) {
        if (name.contains(kw)) {
          return wShoe;
        }
      }
    }
    // Sepatu tidak dikenali: score netral
    return wShoe * 0.6;
  }

  double _rotationScore(ClothModel cloth) {
    final now = DateTime.now();
    if (cloth.lastWornAt == null) {
      // Belum pernah dipakai: prioritaskan
      return wRotation;
    }

    final daysSince = now.difference(cloth.lastWornAt!).inDays;

    if (daysSince <= 1) {
      return wRotation * 0.1; // baru dipakai: penalty
    } else if (daysSince <= 3) {
      return wRotation * 0.4;
    } else if (daysSince <= 7) {
      return wRotation * 0.7;
    } else if (daysSince <= 14) {
      return wRotation * 0.9;
    }

    // Sudah lama tidak dipakai + frekuensi rendah: prioritaskan
    return wRotation;
  }
}
