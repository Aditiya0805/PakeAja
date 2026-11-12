import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';

/// Exception khusus ketika lemari tidak memiliki kombinasi pakaian
/// yang pantas untuk kategori / agenda tertentu.
class NoSuitableOutfitException implements Exception {
  final String occasion;
  final List<String> missingSlots;
  final String message;

  NoSuitableOutfitException({
    required this.occasion,
    required this.missingSlots,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Intelligent Rule-Based Outfit Recommendation & Grouping Engine
/// Mengelompokkan pakaian berdasarkan kelayakan gaya/agenda secara ketat
/// (misal: pakaian Santai tidak dipaksakan ke Formal, Sport tidak ke Semi-Formal)
/// serta mencocokkan antar item (Top + Bottom / Onepiece + Shoes + Outer).
class RecommendationService {
  // Bobot scoring kriteria utama (Total 100)
  static const double wOccasion = 35.0;
  static const double wPairStyle = 30.0;
  static const double wShoe = 15.0;
  static const double wColor = 10.0;
  static const double wRotation = 10.0;

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

  static const List<String> _formalKeywords = [
    'tuxedo',
    'tuksedo',
    'batik',
    'kebaya',
    'dasi',
    'pantofel',
    'slacks',
    'slack',
    'stiletto',
    'dress shirt',
  ];

  static const List<String> _strictFormalOnlyKeywords = [
    'tuxedo',
    'tuksedo',
    'dasi',
    'pantofel',
    'kebaya',
    'stiletto',
    'gaun',
  ];

  static const List<String> _sportKeywords = [
    'sport',
    'sporty',
    'olahraga',
    'training',
    'trening',
    'running',
    'jersey',
    'jogger',
    'dryfit',
    'dry-fit',
    'gym',
    'fitness',
    'badminton',
    'futsal',
    'sepak bola',
    'sepakbola',
    'basket',
    'voli',
    'tenis',
    'tennis',
    'padel',
    'golf',
    'renang',
    'yoga',
    'pilates',
    'senam',
    'zumba',
    'sepeda',
    'gowes',
    'cycling',
    'hiking',
    'trekking',
    'outdoor',
    'tracksuit',
    'windbreaker',
    'activewear',
    'athletic',
    'sweatpants',
    'sweatpant',
    'legging',
    'leggings',
    'manset',
    'baselayer',
    'base layer',
    'compression',
    'parasut',
    'baju or',
    'kaos or',
    'kaus or',
    'celana or',
    'setelan olahraga',
    'stelan olahraga',
  ];

  static const List<String> _semiFormalKeywords = [
    'semi',
    'smart casual',
    'smart-casual',
    'blazer',
    'cardigan',
    'kardigan',
    'chino',
    'chinos',
    'oxford',
    'turtleneck',
    'loafers',
    'loafer',
    'derby',
    'linen',
    'rajut',
    'knit',
    'waffle',
    'blouse',
    'blus',
    'tunik',
    'tunic',
    'flat shoes',
    'heels',
    'wedges',
    'korsa',
    'almamater',
    'almet',
    'organisasi',
    'koko',
  ];

  /// Item santai yang sama sekali tidak pantas untuk formal, semi-formal, kuliah, organisasi, maupun olahraga.
  static const List<String> _nonSportRelaxedBlockers = [
    'sandal',
    'slop',
    'flip flop',
    'flip-flop',
    'piyama',
    'tidur',
    'ripped',
    'sobek',
    'pantai',
    'hawaii',
  ];

  /// Item santai yang khusus tidak pantas untuk formal/semi-formal/kuliah/organisasi
  /// (termasuk celana pendek / singlet / tank top).
  static const List<String> _relaxedOnlyBlockers = [
    ..._nonSportRelaxedBlockers,
    'celana pendek',
    'singlet',
    'tank top',
    'crop top',
    'kolor',
  ];

  static const List<String> _strictlyCasualKeywords = [
    'kaos',
    'kaus',
    't-shirt',
    'tshirt',
    'oblong',
    'hoodie',
    'sweatshirt',
    'jeans',
    'denim',
    'cargo',
    'flanel',
    'santai',
    'casual',
    'hangout',
  ];

  static const List<String> _sneakerKeywords = [
    'sneaker',
    'sneakers',
    'court',
    'canvas',
    'kanvas',
  ];

  bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  bool _containsWord(String text, String word) =>
      RegExp('(^|[^a-z0-9])${RegExp.escape(word)}([^a-z0-9]|\$)')
          .hasMatch(text);

  bool _hasStrictFormalOnlyKeyword(String name) =>
      _containsAny(name, _strictFormalOnlyKeywords) ||
      _containsWord(name, 'jas') ||
      _containsWord(name, 'suit');

  bool _hasFormalKeyword(String name) {
    if (_hasStrictFormalOnlyKeyword(name)) return true;
    if (_containsAny(name, _formalKeywords)) return true;
    if (_containsWord(name, 'formal') &&
        !name.contains('semi-formal') &&
        !name.contains('semi formal')) {
      return true;
    }
    if (name.contains('celana') &&
        (name.contains('bahan') ||
            name.contains('kain') ||
            name.contains('wol') ||
            name.contains('dasar') ||
            name.contains('kerja'))) {
      return true;
    }
    if (name.contains('rok') &&
        (name.contains('bahan') ||
            name.contains('span') ||
            name.contains('kerja') ||
            name.contains('formal'))) {
      return true;
    }
    return false;
  }

  bool _hasSportKeyword(String name) =>
      _containsAny(name, _sportKeywords) ||
      _containsWord(name, 'active') ||
      _containsWord(name, 'lari') ||
      _containsWord(name, 'bola');

  bool _hasSemiFormalKeyword(String name) {
    if (_containsAny(name, _semiFormalKeywords)) return true;
    if (_containsWord(name, 'polo') ||
        _containsWord(name, 'vest') ||
        _containsWord(name, 'pdh') ||
        _containsWord(name, 'pdl')) {
      return true;
    }
    if (name.contains('kemeja') &&
        !name.contains('pantai') &&
        !name.contains('hawaii') &&
        !name.contains('flanel') &&
        !name.contains('denim') &&
        !name.contains('jeans')) {
      return true;
    }
    return false;
  }

  bool _hasShortPantsWord(String name) =>
      (_containsWord(name, 'short') && !name.contains('short sleeve')) ||
      _containsWord(name, 'shorts');

  bool _hasRelaxedOnlyBlocker(String name) =>
      _containsAny(name, _relaxedOnlyBlockers) || _hasShortPantsWord(name);

  bool _hasStrictlyCasualKeyword(String name) =>
      _containsAny(name, _strictlyCasualKeywords) ||
      _hasRelaxedOnlyBlocker(name);

  bool _hasSneakerKeyword(String name) => _containsAny(name, _sneakerKeywords);

  bool _isBreathableSportTop(String name) {
    if (_containsAny(name, _nonSportRelaxedBlockers)) return false;
    if (name.contains('santai') ||
        name.contains('hangout') ||
        name.contains('flanel') ||
        name.contains('denim') ||
        name.contains('jeans') ||
        name.contains('kemeja') ||
        name.contains('blazer') ||
        name.contains('batik') ||
        name.contains('blouse') ||
        name.contains('blus')) {
      return false;
    }
    return name.contains('kaos') ||
        name.contains('kaus') ||
        name.contains('t-shirt') ||
        name.contains('tshirt') ||
        name.contains('oblong') ||
        name.contains('singlet') ||
        name.contains('tank top') ||
        name.contains('crop top');
  }

  bool _isNeatShirtForFormal(ClothModel cloth, String name) {
    if (cloth.category != ClothCategory.top &&
        cloth.category != ClothCategory.onepiece) {
      return false;
    }
    if (name.contains('pantai') ||
        name.contains('hawaii') ||
        name.contains('flanel') ||
        name.contains('denim') ||
        name.contains('jeans') ||
        name.contains('santai') ||
        name.contains('hangout') ||
        _containsWord(name, 'pdh') ||
        _containsWord(name, 'pdl') ||
        name.contains('korsa')) {
      return false;
    }
    return name.contains('kemeja') ||
        name.contains('blouse') ||
        name.contains('blus') ||
        name.contains('tunik');
  }

  /// Mengecek apakah user punya cukup item di lemari secara umum
  bool canRecommend(List<ClothModel> clothes) {
    final tops = clothes.where((c) => c.category == ClothCategory.top).length;
    final bottoms =
        clothes.where((c) => c.category == ClothCategory.bottom).length;
    final onepieces =
        clothes.where((c) => c.category == ClothCategory.onepiece).length;
    final shoes = clothes.where((c) => c.category == ClothCategory.shoes).length;

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

  /// Menyarankan daftar gaya pakaian otomatis dari nama pakaian saat input/edit.
  List<ClothStyle> suggestStylesForName(
    String name, {
    ClothCategory? category,
  }) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) {
      if (category == ClothCategory.outer) {
        return const [ClothStyle.casual];
      }
      return const [ClothStyle.casual];
    }

    if (_hasSportKeyword(lower)) {
      return const [ClothStyle.sport];
    }

    if (_hasFormalKeyword(lower)) {
      if (_hasStrictFormalOnlyKeyword(lower)) {
        return const [ClothStyle.formal];
      }
      return const [ClothStyle.formal, ClothStyle.semiFormal];
    }

    if (_hasRelaxedOnlyBlocker(lower)) {
      return const [ClothStyle.casual];
    }

    if (_hasSemiFormalKeyword(lower)) {
      // Kemeja flanel/pantai sudah terfilter di _hasSemiFormalKeyword;
      // kemeja biasa, chino, cardigan, polo cocok untuk Semi-formal & Smart Casual.
      if (lower.contains('blazer') ||
          lower.contains('loafer') ||
          lower.contains('derby') ||
          lower.contains('oxford')) {
        return const [ClothStyle.semiFormal];
      }
      return const [ClothStyle.semiFormal, ClothStyle.casual];
    }

    return const [ClothStyle.casual];
  }

  /// Mengembalikan himpunan gaya efektif item untuk pengelompokan yang konsisten.
  Set<String> getEffectiveStyleValues(ClothModel cloth) =>
      _getEffectiveStyles(cloth);

  /// Mengecek apakah sebuah pakaian layak dipakai pada acara/agenda tertentu.
  /// Contoh: pakaian khusus Santai (kaos santai, celana pendek, sandal, jeans)
  /// tidak boleh dipaksakan masuk ke kategori Formal.
  bool isSuitableForOccasion(ClothModel cloth, String occasion) {
    final normOccasion = normalizeOccasion(occasion);
    final styles = _getEffectiveStyles(cloth);
    final name = cloth.name.toLowerCase();

    switch (normOccasion) {
      case 'formal':
        if (styles.contains('sport') || _hasSportKeyword(name)) return false;
        if (_hasRelaxedOnlyBlocker(name) || _hasSneakerKeyword(name)) {
          return false;
        }
        if (styles.contains('formal')) return true;
        // Semi-formal murni (tanpa unsur casual) atau kemeja/blus polos tetap layak untuk formal
        if (styles.contains('semi-formal') &&
            ((!styles.contains('casual') && !_hasStrictlyCasualKeyword(name)) ||
                _isNeatShirtForFormal(cloth, name))) {
          return true;
        }
        return false;

      case 'organization':
        if (styles.contains('sport') || _hasSportKeyword(name)) return false;
        if (_hasRelaxedOnlyBlocker(name)) return false;
        if (styles.contains('formal') || styles.contains('semi-formal')) {
          return true;
        }
        // Forum organisasi kampus/komunitas juga dapat memakai jeans polos rapi atau sneakers bersih
        if (cloth.category == ClothCategory.bottom &&
            (name.contains('jeans') || name.contains('denim'))) {
          return true;
        }
        if (cloth.category == ClothCategory.shoes &&
            _hasSneakerKeyword(name)) {
          return true;
        }
        return false;

      case 'semi-formal':
        if (styles.contains('sport') || _hasSportKeyword(name)) return false;
        if (_hasRelaxedOnlyBlocker(name)) return false;
        if (styles.contains('semi-formal') || styles.contains('formal')) {
          return true;
        }
        // Sneakers minimalis (tanpa unsur lari/olahraga) masih layak smart-casual
        if (cloth.category == ClothCategory.shoes &&
            _hasSneakerKeyword(name)) {
          return true;
        }
        return false;

      case 'campus':
        if (_hasRelaxedOnlyBlocker(name)) return false;
        if (_hasStrictFormalOnlyKeyword(name)) return false;
        if (styles.contains('sport') && !styles.contains('casual')) {
          return false;
        }
        return styles.contains('semi-formal') || styles.contains('casual');

      case 'casual':
        if (_hasStrictFormalOnlyKeyword(name)) return false;
        // Item yang murni formal (mis. Batik/Celana Bahan tanpa casual/semi-formal) tidak untuk santai
        if (styles.contains('formal') &&
            !styles.contains('casual') &&
            !styles.contains('semi-formal')) {
          return false;
        }
        if (styles.contains('formal') &&
            _hasFormalKeyword(name) &&
            !styles.contains('casual')) {
          return false;
        }
        return styles.contains('casual') || styles.contains('semi-formal');

      case 'sport':
        if (styles.contains('formal') ||
            styles.contains('semi-formal') ||
            _hasFormalKeyword(name) ||
            _hasSemiFormalKeyword(name)) {
          return false;
        }
        // Item santai non-olahraga (sandal, piyama, pantai, sobek, jeans, chino) tetap ditolak
        if (_containsAny(name, _nonSportRelaxedBlockers)) return false;
        if (name.contains('jeans') ||
            name.contains('denim') ||
            name.contains('chino') ||
            name.contains('cargo') ||
            name.contains('flanel') ||
            name.contains('santai') ||
            name.contains('hangout') ||
            name.contains('kulit') ||
            name.contains('leather') ||
            name.contains('slip on')) {
          return false;
        }
        // Item Sport atau bertema olahraga (termasuk celana pendek olahraga, singlet lari, legging)
        if (styles.contains('sport') || _hasSportKeyword(name)) return true;
        // Atasan kaos/singlet breathable (bukan kemeja/santai/pantai) dapat dipakai olahraga
        if (cloth.category == ClothCategory.top && _isBreathableSportTop(name)) {
          return true;
        }
        // Celana pendek / legging polos (tanpa unsur pantai/jeans/tidur/santai) layak untuk olahraga
        if (cloth.category == ClothCategory.bottom &&
            (name.contains('celana pendek') ||
                _hasShortPantsWord(name) ||
                name.contains('legging'))) {
          return true;
        }
        // Sepatu sneakers / sepatu non-formal non-kulit dapat mendampingi olahraga
        if (cloth.category == ClothCategory.shoes &&
            !name.contains('pantofel') &&
            !name.contains('oxford') &&
            !name.contains('derby') &&
            !name.contains('loafer') &&
            !name.contains('heels') &&
            !name.contains('stiletto') &&
            !name.contains('wedges') &&
            !name.contains('flat shoes') &&
            !name.contains('boots')) {
          return true;
        }
        return false;

      default:
        return true;
    }
  }

  /// Daftar label agenda/kategori yang kompatibel dengan pakaian ini.
  List<String> getSuitableOccasions(ClothModel cloth) {
    const agendaLabels = [
      'Santai',
      'Kuliah',
      'Semi Formal',
      'Formal',
      'Organisasi',
      'Olahraga',
    ];
    return agendaLabels
        .where((label) => isSuitableForOccasion(cloth, label))
        .toList();
  }

  /// Mengembalikan daftar slot utama yang masih kurang untuk acara tertentu.
  List<String> missingSlotsForOccasion(
    List<ClothModel> clothes,
    String occasion,
  ) {
    final suitable =
        clothes.where((c) => isSuitableForOccasion(c, occasion)).toList();
    final hasTop = suitable.any((c) => c.category == ClothCategory.top);
    final hasBottom = suitable.any((c) => c.category == ClothCategory.bottom);
    final hasOnepiece =
        suitable.any((c) => c.category == ClothCategory.onepiece);
    final hasShoes = suitable.any((c) => c.category == ClothCategory.shoes);

    if ((hasTop && hasBottom && hasShoes) || (hasOnepiece && hasShoes)) {
      return const [];
    }

    return [
      if (!hasTop && !hasOnepiece) 'Atasan',
      if (!hasBottom && !hasOnepiece) 'Bawahan',
      if (!hasShoes) 'Sepatu',
    ];
  }

  /// Generate rekomendasi outfit otomatis hanya dari pakaian yang layak untuk agenda terkait.
  OutfitRecommendation recommend({
    required List<ClothModel> clothes,
    required String occasion,
    List<String> excludedIds = const [],
  }) {
    final suitableAll =
        clothes.where((c) => isSuitableForOccasion(c, occasion)).toList();

    if (!canRecommend(suitableAll)) {
      final missing = missingSlotsForOccasion(clothes, occasion);
      final missingText =
          missing.isNotEmpty ? ' (kurang: ${missing.join(', ')})' : '';
      throw NoSuitableOutfitException(
        occasion: occasion,
        missingSlots: missing,
        message:
            'Belum ada pakaian yang cocok untuk kategori $occasion$missingText. '
            'Pakaian dari kategori lain yang tidak sesuai tidak dipaksakan masuk ke kategori $occasion.',
      );
    }

    var pool =
        suitableAll.where((c) => !excludedIds.contains(c.id)).toList();
    if (!canRecommend(pool)) {
      // Tetap hanya gunakan pakaian yang layak untuk agenda ini (jangan campur kategori yang tidak sesuai)
      pool = List.from(suitableAll);
    }

    final normOccasion = normalizeOccasion(occasion);

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

    // Skenario 1: Pasangkan Atasan + Bawahan + Sepatu (+ Outer/Aksesori yang sesuai)
    if (tops.isNotEmpty && bottoms.isNotEmpty && shoesList.isNotEmpty) {
      bestCombination = _findBestTopBottomSet(
        tops: tops,
        bottoms: bottoms,
        shoesList: shoesList,
        outers: outers,
        accessories: accessories,
        normOccasion: normOccasion,
      );
    }

    // Skenario 2: One-piece + Sepatu (+ Outer/Aksesori yang sesuai)
    if (bestCombination == null &&
        onepieces.isNotEmpty &&
        shoesList.isNotEmpty) {
      bestCombination = _findBestOnepieceSet(
        onepieces: onepieces,
        shoesList: shoesList,
        outers: outers,
        accessories: accessories,
        normOccasion: normOccasion,
      );
    }

    if (bestCombination == null) {
      final missing = missingSlotsForOccasion(clothes, occasion);
      throw NoSuitableOutfitException(
        occasion: occasion,
        missingSlots: missing,
        message:
            'Tidak ditemukan kombinasi pakaian yang sesuai untuk kategori $occasion.',
      );
    }

    final selectedItems = bestCombination.items;
    final itemIds = selectedItems.map((c) => c.id).toList();

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

    final finalScore = bestCombination.totalScore.clamp(86.0, 99.0);

    return OutfitRecommendation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemIds: itemIds,
      occasion: occasion,
      score: finalScore,
      details: details,
    );
  }

  // ==================== NORMALISASI AGENDA / OCCASION ====================
  String normalizeOccasion(String occasion) {
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
  Set<String> _getEffectiveStyles(ClothModel cloth) {
    final styles = <String>{};
    for (final s in cloth.styles) {
      styles.add(s.value.toLowerCase());
    }

    final name = cloth.name.toLowerCase();
    final hasFormalKw = _hasFormalKeyword(name);
    final hasSportKw = _hasSportKeyword(name);
    final hasSemiFormalKw = _hasSemiFormalKeyword(name);
    final hasStrictlyCasualKw = _hasStrictlyCasualKeyword(name);
    final hasSneakerKw = _hasSneakerKeyword(name);

    if (hasFormalKw) {
      styles.add('formal');
      if (!_hasStrictFormalOnlyKeyword(name)) {
        styles.add('semi-formal');
      }
      if (!name.contains('santai') && !name.contains('casual')) {
        styles.remove('casual');
      }
      styles.remove('sport');
    } else if (hasSportKw) {
      styles.add('sport');
      styles.remove('formal');
      styles.remove('semi-formal');
      if (!name.contains('santai') && !name.contains('casual')) {
        styles.remove('casual');
      }
    } else {
      if (hasSemiFormalKw && !hasStrictlyCasualKw) {
        styles.add('semi-formal');
      }
      if (hasStrictlyCasualKw || hasSneakerKw) {
        styles.add('casual');
        if (hasStrictlyCasualKw &&
            !cloth.styles.contains(ClothStyle.semiFormal)) {
          styles.remove('semi-formal');
        }
        if (!cloth.styles.contains(ClothStyle.formal)) {
          styles.remove('formal');
        }
      }
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
        if (clothStyles.contains('formal')) return 0.70;
        if (clothStyles.contains('casual')) return 0.55;
        return 0.05;

      case 'formal':
        if (clothStyles.contains('formal')) return 1.0;
        if (clothStyles.contains('semi-formal')) return 0.65;
        return 0.0;

      case 'sport':
        if (clothStyles.contains('sport')) return 1.0;
        if (clothStyles.contains('casual')) return 0.40;
        return 0.0;

      case 'casual':
        if (clothStyles.contains('casual')) return 1.0;
        if (clothStyles.contains('semi-formal')) return 0.75;
        return 0.10;

      case 'campus':
        if (clothStyles.contains('semi-formal')) return 1.0;
        if (clothStyles.contains('casual')) return 0.90;
        return 0.15;

      case 'organization':
        if (clothStyles.contains('formal')) return 1.0;
        if (clothStyles.contains('semi-formal')) return 0.95;
        if (clothStyles.contains('casual')) return 0.45;
        return 0.0;

      default:
        return 0.8;
    }
  }

  // ==================== KONSISTENSI GAYA ANTAR PASANGAN ====================
  double _pairStyleConsistency(
    Set<String> stylesA,
    Set<String> stylesB,
    String normOccasion,
  ) {
    if (normOccasion == 'semi-formal') {
      if (stylesA.contains('semi-formal') && stylesB.contains('semi-formal')) {
        return 1.0;
      }
      if (stylesA.contains('sport') || stylesB.contains('sport')) {
        return 0.05;
      }
      if (stylesA.contains('semi-formal') || stylesB.contains('semi-formal')) {
        return 0.80;
      }
      return 0.50;
    }

    if (normOccasion == 'formal') {
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
      if (stylesA.contains('semi-formal') && stylesB.contains('semi-formal')) {
        return 0.75;
      }
      return 0.10;
    }

    if (normOccasion == 'sport') {
      if (stylesA.contains('sport') && stylesB.contains('sport')) {
        return 1.0;
      }
      if (stylesA.contains('sport') || stylesB.contains('sport')) {
        return 0.70;
      }
      return 0.40;
    }

    if (normOccasion == 'casual') {
      if (stylesA.contains('casual') && stylesB.contains('casual')) {
        return 1.0;
      }
      if (stylesA.contains('semi-formal') || stylesB.contains('semi-formal')) {
        return 0.80;
      }
      return 0.70;
    }

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
      if (_hasSneakerKeyword(name) || styles.contains('casual')) {
        return 0.80;
      }
      return 0.10;
    }

    if (normOccasion == 'formal') {
      if (name.contains('pantofel') ||
          name.contains('oxford') ||
          name.contains('derby') ||
          name.contains('stiletto') ||
          styles.contains('formal')) {
        return 1.0;
      }
      if (name.contains('loafer') ||
          (styles.contains('semi-formal') && !styles.contains('casual'))) {
        return 0.85;
      }
      return 0.0;
    }

    if (normOccasion == 'sport') {
      if (name.contains('running') ||
          name.contains('sport') ||
          name.contains('training') ||
          styles.contains('sport') ||
          _hasSportKeyword(name)) {
        return 1.0;
      }
      if (_hasSneakerKeyword(name)) {
        return 0.80;
      }
      if (isSuitableForOccasion(shoe, 'Olahraga')) {
        return 0.45;
      }
      return 0.0;
    }

    if (normOccasion == 'casual') {
      if (_hasSneakerKeyword(name) ||
          name.contains('slip on') ||
          name.contains('sandal') ||
          styles.contains('casual')) {
        return 1.0;
      }
      return 0.75;
    }

    if (normOccasion == 'organization') {
      if (name.contains('pantofel') ||
          name.contains('oxford') ||
          name.contains('derby') ||
          name.contains('loafer') ||
          styles.contains('formal') ||
          styles.contains('semi-formal')) {
        return 1.0;
      }
      return 0.65;
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
      if (styles.contains('formal')) return 0.80;
      return 0.20;
    }

    if (normOccasion == 'formal') {
      if (name.contains('blazer') ||
          name.contains('jas') ||
          styles.contains('formal')) {
        return 1.0;
      }
      if (styles.contains('semi-formal') && !styles.contains('casual')) {
        return 0.75;
      }
      return 0.0;
    }

    if (normOccasion == 'sport') {
      if (name.contains('windbreaker') ||
          name.contains('track') ||
          name.contains('sport') ||
          styles.contains('sport')) {
        return 1.0;
      }
      return 0.0;
    }

    if (normOccasion == 'casual') {
      if (_hasStrictFormalOnlyKeyword(name)) return 0.0;
      if (styles.contains('casual') || styles.contains('semi-formal')) {
        return 0.90;
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
          matchTotal += 0.85;
        } else if (_neutral.contains(c1) || _neutral.contains(c2)) {
          matchTotal += 1.0;
        } else if (_analogous[c1]?.contains(c2) ?? false) {
          matchTotal += 0.95;
        } else {
          matchTotal += 0.35;
        }
      }
    }

    return comparisons > 0 ? (matchTotal / comparisons) : 1.0;
  }

  // ==================== ROTASI PEMAKAIAN ====================
  double _rotationScore(ClothModel cloth) {
    if (cloth.lastWornAt == null) return 1.0;

    final days = DateTime.now().difference(cloth.lastWornAt!).inDays;
    if (days <= 1) return 0.20;
    if (days <= 3) return 0.50;
    if (days <= 7) return 0.75;
    if (days <= 14) return 0.90;
    return 1.0;
  }

  ClothModel? _pickBestOuter({
    required List<ClothModel> outers,
    required List<String> baseColors,
    required String normOccasion,
  }) {
    ClothModel? bestOuter;
    double bestScore = 0;
    for (final outer in outers) {
      final oOcc = _outerScoreForOccasion(outer, normOccasion);
      if (oOcc >= 0.70) {
        final oColor = _colorHarmonyScore([...baseColors, outer.color]);
        final oScore = (oOcc * 0.7) + (oColor * 0.3);
        if (oScore > bestScore) {
          bestScore = oScore;
          bestOuter = outer;
        }
      }
    }
    return bestOuter;
  }

  ClothModel? _pickBestAccessory({
    required List<ClothModel> accessories,
    required List<String> baseColors,
    required String normOccasion,
  }) {
    ClothModel? bestAcc;
    double bestScore = 0;
    for (final acc in accessories) {
      final aff = _occasionAffinity(_getEffectiveStyles(acc), normOccasion);
      if (aff >= 0.50) {
        final cHarm = _colorHarmonyScore([...baseColors, acc.color]);
        final score = (aff * 0.7) + (cHarm * 0.3);
        if (score > bestScore) {
          bestScore = score;
          bestAcc = acc;
        }
      }
    }
    return bestAcc;
  }

  // ==================== PENCARIAN KOMBINASI TERBAIK ====================
  _BestOutfitCombination? _findBestTopBottomSet({
    required List<ClothModel> tops,
    required List<ClothModel> bottoms,
    required List<ClothModel> shoesList,
    required List<ClothModel> outers,
    required List<ClothModel> accessories,
    required String normOccasion,
  }) {
    ClothModel? bestTop;
    ClothModel? bestBottom;
    ClothModel? bestShoe;
    ClothModel? bestOuter;
    ClothModel? bestAccessory;
    double maxScore = -1;

    for (final top in tops) {
      final topStyles = _getEffectiveStyles(top);
      final affTop = _occasionAffinity(topStyles, normOccasion);

      for (final bottom in bottoms) {
        final bottomStyles = _getEffectiveStyles(bottom);
        final affBottom = _occasionAffinity(bottomStyles, normOccasion);

        final pairConsistency =
            _pairStyleConsistency(topStyles, bottomStyles, normOccasion);
        final colorPair = _colorHarmonyScore([top.color, bottom.color]);
        final rotTopBottom =
            (_rotationScore(top) + _rotationScore(bottom)) / 2;

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

        if (candidateShoe == null) continue;

        final candidateOuter = _pickBestOuter(
          outers: outers,
          baseColors: [top.color, bottom.color],
          normOccasion: normOccasion,
        );
        final candidateAcc = _pickBestAccessory(
          accessories: accessories,
          baseColors: [top.color, bottom.color],
          normOccasion: normOccasion,
        );

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

    if (bestTop == null || bestBottom == null || bestShoe == null) {
      return null;
    }

    return _BestOutfitCombination(
      items: [
        bestTop,
        bestBottom,
        bestShoe,
        if (bestOuter != null) bestOuter,
        if (bestAccessory != null) bestAccessory,
      ],
      totalScore: maxScore,
    );
  }

  _BestOutfitCombination? _findBestOnepieceSet({
    required List<ClothModel> onepieces,
    required List<ClothModel> shoesList,
    required List<ClothModel> outers,
    required List<ClothModel> accessories,
    required String normOccasion,
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

      if (candidateShoe == null) continue;

      final candidateOuter = _pickBestOuter(
        outers: outers,
        baseColors: [op.color],
        normOccasion: normOccasion,
      );
      final candidateAcc = _pickBestAccessory(
        accessories: accessories,
        baseColors: [op.color],
        normOccasion: normOccasion,
      );

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

    if (bestOnepiece == null || bestShoe == null) {
      return null;
    }

    return _BestOutfitCombination(
      items: [
        bestOnepiece,
        bestShoe,
        if (bestOuter != null) bestOuter,
        if (bestAccessory != null) bestAccessory,
      ],
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
