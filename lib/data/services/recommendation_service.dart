import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';

/// Intelligent Rule-Based Outfit Recommendation Engine
/// Mengotomatisasi pencocokan antar pakaian (Top + Bottom / Onepiece + Shoes + Outer)
/// sesuai dengan agenda / occasion (Semi-Formal, Formal, Santai, Kuliah, Olahraga, dll).
class RecommendationService {
  // Bobot scoring kriteria utama (Total 100)
  static const double wOccasion = 35.0; // Kesesuaian masing-masing pakaian dengan acara
  static const double wPairStyle = 30.0; // Keselarasan gaya antar pakaian (Top x Bottom x Shoes)
  static const double wShoe = 15.0; // Kesesuaian alas kaki / sepatu dengan tema gaya
  static const double wColor = 10.0; // Keharmonisan warna
  static const double wRotation = 10.0; // Rotasi pemakaian (pakaian yang belum baru dipakai)

  // Warna netral (mudah dipadukan dengan warna apa pun)
  static const List<String> _neutral = [
    'black',
    'white',
    'gray',
    'navy',
    'cream',
  ];

  // Palet warna analogus / komplementer yang serasi
  static const Map<String, List<String>> _analogous = {
    'black': ['white', 'gray', 'navy', 'brown', 'cream', 'red', 'blue'],
    'white': ['black', 'gray', 'navy', 'blue', 'cream', 'brown', 'green'],
    'gray': ['black', 'white', 'navy', 'blue', 'cream'],
    'navy': ['white', 'gray', 'blue', 'brown', 'cream', 'black'],
    'blue': ['white', 'gray', 'navy', 'cream', 'black'],
    'red': ['white', 'black', 'navy', 'gray'],
    'green': ['white', 'brown', 'cream', 'black', 'navy'],
    'brown': ['cream', 'white', 'navy', 'green', 'black'],
    'cream': ['brown', 'navy', 'white', 'black', 'green', 'blue'],
    'other': ['black', 'white', 'gray', 'navy', 'cream'],
  };

  /// Mengecek apakah user punya cukup item di lemari untuk rekomendasi
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

  /// Kembalikan status checklist kategori pakaian yang belum terpenuhi
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

  /// Generate rekomendasi outfit otomatis yang mencocokkan gaya antar pakaian secara presisi.
  OutfitRecommendation recommend({
    required List<ClothModel> clothes,
    required String occasion,
    List<String> excludedIds = const [],
  }) {
    // Filter pool pakaian yang tidak di-exclude
    var pool = clothes.where((c) => !excludedIds.contains(c.id)).toList();
    if (!canRecommend(pool)) {
      // Jika setelah exclusion tidak cukup, gunakan seluruh pakaian
      pool = List.from(clothes);
    }

    if (!canRecommend(pool)) {
      throw Exception('Belum ada pakaian yang cukup untuk rekomendasi.');
    }

    final normOccasion = _normalizeOccasion(occasion);

    final tops = pool.where((c) => c.category == ClothCategory.top).toList();
    final bottoms =
        pool.where((c) => c.category == ClothCategory.bottom).toList();
    final onepieces =
        pool.where((c) => c.category == ClothCategory.onepiece).toList();
    final shoesList =
        pool.where((c) => c.category == ClothCategory.shoes).toList();
    final outers =
        pool.where((c) => c.category == ClothCategory.outer).toList();
    final accessories =
        pool.where((c) => c.category == ClothCategory.accessory).toList();

    _BestOutfitCombination? bestCombination;

    // Skenario 1: Pasangkan Atasan (Top) + Bawahan (Bottom) + Sepatu + Outer
    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      bestCombination = _findBestTopBottomSet(
        tops: tops,
        bottoms: bottoms,
        shoesList: shoesList,
        outers: outers,
        accessories: accessories,
        normOccasion: normOccasion,
        rawOccasion: occasion,
      );
    }

    // Skenario 2: Jika tidak ada top/bottom atau One-piece lebih unggul
    if (bestCombination == null && onepieces.isNotEmpty) {
      bestCombination = _findBestOnepieceSet(
        onepieces: onepieces,
        shoesList: shoesList,
        outers: outers,
        accessories: accessories,
        normOccasion: normOccasion,
        rawOccasion: occasion,
      );
    }

    if (bestCombination == null) {
      throw Exception('Tidak dapat menemukan kombinasi pakaian yang sesuai.');
    }

    final selectedItems = bestCombination.items;
    final itemIds = selectedItems.map((c) => c.id).toList();

    // Hitung detail skor untuk tiap item
    final details = <ClothScoreDetail>[];
    for (final item in selectedItems) {
      final s = _scoreItem(
        cloth: item,
        normOccasion: normOccasion,
        allSelected: selectedItems,
      );
      details.add(ClothScoreDetail(
        clothId: item.id,
        clothName: item.name,
        score: s,
        reason: _generateItemReason(item, normOccasion, occasion),
      ));
    }

    // Hitung score serasi akhir (persentase 88% - 99%)
    final finalScore = (bestCombination.totalScore).clamp(86.0, 99.0);

    return OutfitRecommendation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemIds: itemIds,
      occasion: occasion,
      score: finalScore,
      details: details,
    );
  }

  // ==================== NORMALISASI AGENDA / OCCASION ====================
  String _normalizeOccasion(String occasion) {
    final lower = occasion.toLowerCase();
    if (lower.contains('semi') || lower.contains('smart')) return 'semi-formal';
    if (lower.contains('formal')) return 'formal';
    if (lower.contains('olahraga') ||
        lower.contains('sport') ||
        lower.contains('active')) {
      return 'sport';
    }
    if (lower.contains('santai') ||
        lower.contains('casual') ||
        lower.contains('cozy') ||
        lower.contains('kafe') ||
        lower.contains('hangout')) {
      return 'casual';
    }
    if (lower.contains('kuliah')) return 'campus';
    if (lower.contains('organisasi') || lower.contains('rapat')) {
      return 'organization';
    }
    return 'casual';
  }

  // ==================== SMART STYLE DETECTION ====================
  /// Mendeteksi gaya pakaian secara otomatis dari kategori, input style, dan kata kunci nama
  Set<String> _getEffectiveStyles(ClothModel cloth) {
    final styles = <String>{};
    for (final s in cloth.styles) {
      styles.add(s.value.toLowerCase());
    }

    final name = cloth.name.toLowerCase();
    bool hasFormalKeyword = false;
    bool hasSportKeyword = false;

    // Kata kunci Formal
    if (name.contains('formal') ||
        name.contains('jas') ||
        name.contains('batik') ||
        name.contains('pantofel') ||
        name.contains('tuxedo') ||
        name.contains('dasi') ||
        (name.contains('celana') && name.contains('bahan')) ||
        (name.contains('rok') && name.contains('bahan'))) {
      styles.add('formal');
      hasFormalKeyword = true;
    }

    // Kata kunci Sport / Olahraga
    if (name.contains('sport') ||
        name.contains('olahraga') ||
        name.contains('training') ||
        name.contains('running') ||
        name.contains('jersey') ||
        name.contains('jogger') ||
        name.contains('dryfit') ||
        name.contains('dry-fit') ||
        name.contains('gym') ||
        name.contains('badminton') ||
        name.contains('futsal')) {
      styles.add('sport');
      hasSportKeyword = true;
    }

    // Kata kunci Semi-Formal
    if (name.contains('semi') ||
        name.contains('blazer') ||
        name.contains('cardigan') ||
        name.contains('chino') ||
        name.contains('oxford') ||
        name.contains('turtleneck') ||
        name.contains('kemeja') ||
        name.contains('loafers') ||
        name.contains('loafer') ||
        name.contains('polo') ||
        name.contains('linen') ||
        name.contains('rajut') ||
        name.contains('waffle')) {
      styles.add('semi-formal');
    }

    // Jika item terdeteksi kuat formal atau sport, bersihkan gaya default yang bertentangan
    if (hasFormalKeyword) {
      styles.remove('casual');
      styles.remove('sport');
    } else if (hasSportKeyword) {
      styles.remove('formal');
      styles.remove('semi-formal');
      if (!name.contains('santai') && !name.contains('casual')) {
        styles.remove('casual');
      }
    }

    // Kata kunci Casual / Santai
    if (name.contains('kaos') ||
        name.contains('t-shirt') ||
        name.contains('tshirt') ||
        name.contains('jeans') ||
        name.contains('denim') ||
        name.contains('hoodie') ||
        name.contains('sneakers') ||
        name.contains('sandal') ||
        name.contains('santai') ||
        name.contains('casual')) {
      styles.add('casual');
    }

    if (styles.isEmpty) {
      styles.add('casual');
    }

    return styles;
  }

  // ==================== KESESUAIAN GAYA DENGAN ACARA ====================
  double _occasionAffinity(Set<String> clothStyles, String normOccasion) {
    switch (normOccasion) {
      case 'semi-formal':
        if (clothStyles.contains('semi-formal')) return 1.0;
        if (clothStyles.contains('casual')) return 0.55;
        if (clothStyles.contains('formal')) return 0.50;
        return 0.05; // Hindari sport untuk semi-formal

      case 'formal':
        if (clothStyles.contains('formal')) return 1.0;
        if (clothStyles.contains('semi-formal')) return 0.65;
        if (clothStyles.contains('casual')) return 0.10;
        return 0.0; // Hindari sport / casual untuk formal

      case 'sport':
        if (clothStyles.contains('sport')) return 1.0;
        if (clothStyles.contains('casual')) return 0.40;
        return 0.0; // Hindari formal / semi-formal untuk sport

      case 'casual':
        if (clothStyles.contains('casual')) return 1.0;
        if (clothStyles.contains('semi-formal')) return 0.75;
        if (clothStyles.contains('sport')) return 0.60;
        return 0.10;

      case 'campus':
        if (clothStyles.contains('semi-formal')) return 1.0;
        if (clothStyles.contains('casual')) return 0.90;
        if (clothStyles.contains('formal')) return 0.60;
        return 0.15;

      case 'organization':
        if (clothStyles.contains('formal')) return 1.0;
        if (clothStyles.contains('semi-formal')) return 0.95;
        if (clothStyles.contains('casual')) return 0.35;
        return 0.0;

      default:
        return 0.8;
    }
  }

  // ==================== KONSISTENSI GAYA ANTAR PASANGAN ====================
  /// Menghitung keserasian gaya antar 2 pakaian (misal: Atasan Semi-Formal HARUS dipasangkan dengan Bawahan Semi-Formal)
  double _pairStyleConsistency(
    Set<String> stylesA,
    Set<String> stylesB,
    String normOccasion,
  ) {
    if (normOccasion == 'semi-formal') {
      // Jika keduanya sama-sama Semi-Formal -> Nilai sempurna!
      if (stylesA.contains('semi-formal') && stylesB.contains('semi-formal')) {
        return 1.0;
      }
      // Tabrakan gaya: salah satu pakaian olahraga
      if (stylesA.contains('sport') || stylesB.contains('sport')) {
        return 0.05;
      }
      // Semi-formal dipadu dengan smart casual yang rapi
      if (stylesA.contains('semi-formal') || stylesB.contains('semi-formal')) {
        return 0.75;
      }
      return 0.40;
    }

    if (normOccasion == 'formal') {
      // Formal dipasangkan dengan Formal -> Nilai sempurna!
      if (stylesA.contains('formal') && stylesB.contains('formal')) {
        return 1.0;
      }
      if (stylesA.contains('sport') || stylesB.contains('sport')) {
        return 0.0;
      }
      if ((stylesA.contains('formal') && stylesB.contains('semi-formal')) ||
          (stylesA.contains('semi-formal') && stylesB.contains('formal'))) {
        return 0.85;
      }
      return 0.15;
    }

    if (normOccasion == 'sport') {
      // Sport dipasangkan dengan Sport -> Nilai sempurna!
      if (stylesA.contains('sport') && stylesB.contains('sport')) {
        return 1.0;
      }
      if (stylesA.contains('formal') || stylesB.contains('formal')) {
        return 0.0;
      }
      if (stylesA.contains('sport') || stylesB.contains('sport')) {
        return 0.60;
      }
      return 0.10;
    }

    if (normOccasion == 'casual') {
      // Casual dipasangkan dengan Casual -> Nilai sempurna!
      if (stylesA.contains('casual') && stylesB.contains('casual')) {
        return 1.0;
      }
      if ((stylesA.contains('formal') && stylesB.contains('sport')) ||
          (stylesA.contains('sport') && stylesB.contains('formal'))) {
        return 0.10;
      }
      if (stylesA.contains('semi-formal') || stylesB.contains('semi-formal')) {
        return 0.80; // Smart casual
      }
      return 0.70;
    }

    // Default: jika ada irisan gaya yang sama
    final common = stylesA.intersection(stylesB);
    if (common.isNotEmpty) return 1.0;
    return 0.65;
  }

  // ==================== KESESUAIAN SEPATU ====================
  double _shoeScoreForOccasion(ClothModel shoe, String normOccasion) {
    final name = shoe.name.toLowerCase();
    final styles = _getEffectiveStyles(shoe);

    if (normOccasion == 'semi-formal') {
      if (name.contains('loafer') ||
          name.contains('oxford') ||
          name.contains('derby') ||
          name.contains('slip on') ||
          name.contains('court') ||
          styles.contains('semi-formal')) {
        return 1.0;
      }
      if (name.contains('sneaker') || styles.contains('casual')) {
        return 0.80; // Clean minimalist sneakers cocok untuk smart casual
      }
      if (name.contains('running') ||
          name.contains('sport') ||
          styles.contains('sport')) {
        return 0.10; // Hindari sepatu lari untuk semi-formal
      }
      return 0.70;
    }

    if (normOccasion == 'formal') {
      if (name.contains('pantofel') ||
          name.contains('oxford') ||
          name.contains('derby') ||
          styles.contains('formal')) {
        return 1.0;
      }
      if (name.contains('loafer') || styles.contains('semi-formal')) {
        return 0.85;
      }
      return 0.10;
    }

    if (normOccasion == 'sport') {
      if (name.contains('running') ||
          name.contains('sport') ||
          name.contains('training') ||
          styles.contains('sport')) {
        return 1.0;
      }
      if (name.contains('sneaker')) {
        return 0.80;
      }
      return 0.05;
    }

    if (normOccasion == 'casual') {
      if (name.contains('sneaker') ||
          name.contains('canvas') ||
          name.contains('slip on') ||
          name.contains('sandal') ||
          styles.contains('casual')) {
        return 1.0;
      }
      return 0.70;
    }

    return 0.80;
  }

  // ==================== KESESUAIAN OUTER / LAYERING ====================
  double _outerScoreForOccasion(ClothModel outer, String normOccasion) {
    final name = outer.name.toLowerCase();
    final styles = _getEffectiveStyles(outer);

    if (normOccasion == 'semi-formal') {
      if (name.contains('blazer') ||
          name.contains('cardigan') ||
          name.contains('knit') ||
          name.contains('waffle') ||
          name.contains('vest') ||
          styles.contains('semi-formal')) {
        return 1.0;
      }
      if (styles.contains('casual')) return 0.60;
      return 0.10;
    }

    if (normOccasion == 'formal') {
      if (name.contains('blazer') ||
          name.contains('jas') ||
          styles.contains('formal')) {
        return 1.0;
      }
      return 0.10;
    }

    if (normOccasion == 'sport') {
      if (name.contains('windbreaker') ||
          name.contains('track') ||
          name.contains('sport') ||
          styles.contains('sport')) {
        return 1.0;
      }
      return 0.20;
    }

    return 0.80;
  }

  // ==================== HARMONI WARNA ====================
  double _colorHarmonyScore(List<String> colors) {
    if (colors.length < 2) return 1.0;

    double matchTotal = 0;
    int comparisons = 0;

    for (int i = 0; i < colors.length; i++) {
      for (int j = i + 1; j < colors.length; j++) {
        final c1 = colors[i].toLowerCase();
        final c2 = colors[j].toLowerCase();
        comparisons++;

        if (c1 == c2) {
          matchTotal += 0.85; // Tone-sur-tone / serasi
        } else if (_neutral.contains(c1) || _neutral.contains(c2)) {
          matchTotal += 1.0; // Warna netral sangat mudah dipadukan
        } else if (_analogous[c1]?.contains(c2) ?? false) {
          matchTotal += 0.95; // Warna analogus harmonis
        } else {
          matchTotal += 0.35; // Kurang serasi
        }
      }
    }

    return comparisons > 0 ? (matchTotal / comparisons) : 1.0;
  }

  // ==================== ROTASI PEMAKAIAN ====================
  double _rotationScore(ClothModel cloth) {
    if (cloth.lastWornAt == null) return 1.0; // Belum pernah dipakai

    final days = DateTime.now().difference(cloth.lastWornAt!).inDays;
    if (days <= 1) return 0.20;
    if (days <= 3) return 0.50;
    if (days <= 7) return 0.75;
    if (days <= 14) return 0.90;
    return 1.0;
  }

  // ==================== PENCARIAN KOMBINASI TERBAIK ====================
  _BestOutfitCombination _findBestTopBottomSet({
    required List<ClothModel> tops,
    required List<ClothModel> bottoms,
    required List<ClothModel> shoesList,
    required List<ClothModel> outers,
    required List<ClothModel> accessories,
    required String normOccasion,
    required String rawOccasion,
  }) {
    ClothModel? bestTop;
    ClothModel? bestBottom;
    ClothModel? bestShoe;
    ClothModel? bestOuter;
    ClothModel? bestAccessory;
    double maxScore = -1;

    // Evaluasi setiap pasangan Atasan dan Bawahan
    for (final top in tops) {
      final topStyles = _getEffectiveStyles(top);
      final affTop = _occasionAffinity(topStyles, normOccasion);

      for (final bottom in bottoms) {
        final bottomStyles = _getEffectiveStyles(bottom);
        final affBottom = _occasionAffinity(bottomStyles, normOccasion);

        // KONSISTENSI GAYA ANTARA ATASAN DAN BAWAHAN (Kunci utama!)
        final pairConsistency =
            _pairStyleConsistency(topStyles, bottomStyles, normOccasion);

        // Harmoni warna Atasan dan Bawahan
        final colorPair = _colorHarmonyScore([top.color, bottom.color]);

        // Rotasi
        final rotTopBottom =
            (_rotationScore(top) + _rotationScore(bottom)) / 2;

        // Cari sepatu terbaik yang serasi dengan pasangan pakaian ini
        ClothModel? candidateShoe;
        double bestShoeScore = 0;
        for (final shoe in shoesList) {
          final sOcc = _shoeScoreForOccasion(shoe, normOccasion);
          final sColor =
              _colorHarmonyScore([top.color, bottom.color, shoe.color]);
          final sRot = _rotationScore(shoe);
          final sScore = (sOcc * 0.6) + (sColor * 0.3) + (sRot * 0.1);
          if (sScore > bestShoeScore) {
            bestShoeScore = sScore;
            candidateShoe = shoe;
          }
        }

        // Cari outer opsional yang serasi (hanya jika ada dan cocok)
        ClothModel? candidateOuter;
        double outerContribution = 0;
        for (final outer in outers) {
          final oOcc = _outerScoreForOccasion(outer, normOccasion);
          if (oOcc >= 0.70) {
            final oColor = _colorHarmonyScore(
                [top.color, bottom.color, outer.color]);
            final oScore = (oOcc * 0.7) + (oColor * 0.3);
            if (oScore > outerContribution) {
              outerContribution = oScore;
              candidateOuter = outer;
            }
          }
        }

        // Cari aksesori opsional jika ada
        ClothModel? candidateAcc;
        if (accessories.isNotEmpty) {
          candidateAcc = accessories.first;
        }

        // Hitung total skor gabungan dari set pakaian ini
        final occasionSubtotal = ((affTop + affBottom) / 2) * wOccasion;
        final styleSubtotal = pairConsistency * wPairStyle;
        final shoeSubtotal = bestShoeScore * wShoe;
        final colorSubtotal = colorPair * wColor;
        final rotSubtotal = rotTopBottom * wRotation;

        final totalSetScore = occasionSubtotal +
            styleSubtotal +
            shoeSubtotal +
            colorSubtotal +
            rotSubtotal;

        if (totalSetScore > maxScore) {
          maxScore = totalSetScore;
          bestTop = top;
          bestBottom = bottom;
          bestShoe = candidateShoe;
          bestOuter = candidateOuter;
          bestAccessory = candidateAcc;
        }
      }
    }

    final selected = <ClothModel>[
      if (bestTop != null) bestTop,
      if (bestBottom != null) bestBottom,
      if (bestShoe != null) bestShoe,
      if (bestOuter != null) bestOuter,
      if (bestAccessory != null) bestAccessory,
    ];

    return _BestOutfitCombination(
      items: selected,
      totalScore: maxScore,
    );
  }

  _BestOutfitCombination _findBestOnepieceSet({
    required List<ClothModel> onepieces,
    required List<ClothModel> shoesList,
    required List<ClothModel> outers,
    required List<ClothModel> accessories,
    required String normOccasion,
    required String rawOccasion,
  }) {
    ClothModel? bestOnepiece;
    ClothModel? bestShoe;
    ClothModel? bestOuter;
    ClothModel? bestAccessory;
    double maxScore = -1;

    for (final op in onepieces) {
      final opStyles = _getEffectiveStyles(op);
      final affOp = _occasionAffinity(opStyles, normOccasion);
      final rotOp = _rotationScore(op);

      ClothModel? candidateShoe;
      double bestShoeScore = 0;
      for (final shoe in shoesList) {
        final sOcc = _shoeScoreForOccasion(shoe, normOccasion);
        final sColor = _colorHarmonyScore([op.color, shoe.color]);
        final sScore = (sOcc * 0.7) + (sColor * 0.3);
        if (sScore > bestShoeScore) {
          bestShoeScore = sScore;
          candidateShoe = shoe;
        }
      }

      ClothModel? candidateOuter;
      for (final outer in outers) {
        final oOcc = _outerScoreForOccasion(outer, normOccasion);
        if (oOcc >= 0.70) {
          candidateOuter = outer;
          break;
        }
      }

      ClothModel? candidateAcc;
      if (accessories.isNotEmpty) candidateAcc = accessories.first;

      final totalSetScore = (affOp * (wOccasion + wPairStyle * 0.6)) +
          (bestShoeScore * wShoe) +
          (rotOp * wRotation);

      if (totalSetScore > maxScore) {
        maxScore = totalSetScore;
        bestOnepiece = op;
        bestShoe = candidateShoe;
        bestOuter = candidateOuter;
        bestAccessory = candidateAcc;
      }
    }

    final selected = <ClothModel>[
      if (bestOnepiece != null) bestOnepiece,
      if (bestShoe != null) bestShoe,
      if (bestOuter != null) bestOuter,
      if (bestAccessory != null) bestAccessory,
    ];

    return _BestOutfitCombination(
      items: selected,
      totalScore: maxScore,
    );
  }

  // ==================== SKOR INDIVIDUAL TIAP ITEM ====================
  double _scoreItem({
    required ClothModel cloth,
    required String normOccasion,
    required List<ClothModel> allSelected,
  }) {
    final styles = _getEffectiveStyles(cloth);
    final affinity = _occasionAffinity(styles, normOccasion);
    final colors = allSelected.map((c) => c.color).toList();
    final colorHarm = _colorHarmonyScore(colors);
    final rot = _rotationScore(cloth);

    final score = (affinity * 60) + (colorHarm * 25) + (rot * 15);
    return score.clamp(80.0, 99.0);
  }

  String _generateItemReason(
    ClothModel item,
    String normOccasion,
    String occasion,
  ) {
    final styles = _getEffectiveStyles(item);
    if (normOccasion == 'semi-formal') {
      if (styles.contains('semi-formal')) {
        return 'Model semi-formal sangat serasi dengan setelan dan agenda $occasion';
      }
      return 'Pilihan smart yang rapi dan selaras dengan tema semi-formal';
    }
    if (normOccasion == 'formal') {
      return 'Model formal yang rapi, berwibawa, dan pas untuk acara $occasion';
    }
    if (normOccasion == 'sport') {
      return 'Material aktif yang fleksibel dan nyaman untuk berolahraga';
    }
    return 'Gaya kasual yang stylish dan nyaman untuk agenda $occasion';
  }
}

class _BestOutfitCombination {
  final List<ClothModel> items;
  final double totalScore;

  _BestOutfitCombination({
    required this.items,
    required this.totalScore,
  });
}
