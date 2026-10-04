import 'package:cloud_firestore/cloud_firestore.dart';

enum ClothCategory { top, bottom, onepiece, outer, shoes, accessory }

enum ClothStyle { casual, formal, semiFormal, sport }

enum ClothWeather { hot, cool, rain }

extension ClothCategoryExt on ClothCategory {
  String get value => name;
  String get label {
    switch (this) {
      case ClothCategory.top:
        return 'Atasan';
      case ClothCategory.bottom:
        return 'Bawahan';
      case ClothCategory.onepiece:
        return 'One-piece';
      case ClothCategory.outer:
        return 'Outer';
      case ClothCategory.shoes:
        return 'Sepatu';
      case ClothCategory.accessory:
        return 'Aksesori';
    }
  }
}

extension ClothStyleExt on ClothStyle {
  String get value {
    switch (this) {
      case ClothStyle.semiFormal:
        return 'semi-formal';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case ClothStyle.casual:
        return 'Casual';
      case ClothStyle.formal:
        return 'Formal';
      case ClothStyle.semiFormal:
        return 'Semi-formal';
      case ClothStyle.sport:
        return 'Sport';
    }
  }

  static ClothStyle fromValue(String v) {
    switch (v) {
      case 'casual':
        return ClothStyle.casual;
      case 'formal':
        return ClothStyle.formal;
      case 'semi-formal':
        return ClothStyle.semiFormal;
      case 'sport':
        return ClothStyle.sport;
      default:
        return ClothStyle.casual;
    }
  }
}

extension ClothWeatherExt on ClothWeather {
  String get value => name;
  String get label {
    switch (this) {
      case ClothWeather.hot:
        return 'Panas';
      case ClothWeather.cool:
        return 'Sejuk';
      case ClothWeather.rain:
        return 'Hujan';
    }
  }
}

/// Warna pakaian (string agar fleksibel)
class ClothColor {
  static const black = 'black';
  static const white = 'white';
  static const gray = 'gray';
  static const navy = 'navy';
  static const blue = 'blue';
  static const red = 'red';
  static const green = 'green';
  static const brown = 'brown';
  static const cream = 'cream';
  static const other = 'other';

  static const all = [
    black, white, gray, navy, blue, red, green, brown, cream, other,
  ];

  static String label(String c) {
    const map = {
      black: 'Hitam',
      white: 'Putih',
      gray: 'Abu-abu',
      navy: 'Navy',
      blue: 'Biru',
      red: 'Merah',
      green: 'Hijau',
      brown: 'Coklat',
      cream: 'Cream',
      other: 'Lainnya',
    };
    return map[c] ?? 'Lainnya';
  }

  /// Warna netral yang mudah dipadukan
  static const neutral = [black, white, gray, navy, cream];

  static bool isNeutral(String c) => neutral.contains(c);
}

class ClothModel {
  final String id;
  final String name;
  final ClothCategory category;
  final String color;
  final List<ClothStyle> styles;
  final ClothWeather weather;
  final String imageUrl;
  final String? thumbUrl;
  final DateTime? lastWornAt;
  final int wearCount;
  final DateTime createdAt;

  const ClothModel({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.styles,
    required this.weather,
    required this.imageUrl,
    this.thumbUrl,
    this.lastWornAt,
    this.wearCount = 0,
    required this.createdAt,
  });

  factory ClothModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ClothModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: _categoryFrom(data['category'] as String?),
      color: data['color'] as String? ?? ClothColor.other,
      styles: (data['styles'] as List<dynamic>?)
              ?.map((s) => ClothStyleExt.fromValue(s as String))
              .toList() ??
          [ClothStyle.casual],
      weather: _weatherFrom(data['weather'] as String?),
      imageUrl: data['imageUrl'] as String? ?? '',
      thumbUrl: data['thumbUrl'] as String?,
      lastWornAt: (data['lastWornAt'] as Timestamp?)?.toDate(),
      wearCount: data['wearCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static ClothCategory _categoryFrom(String? v) {
    switch (v) {
      case 'top':
        return ClothCategory.top;
      case 'bottom':
        return ClothCategory.bottom;
      case 'onepiece':
        return ClothCategory.onepiece;
      case 'outer':
        return ClothCategory.outer;
      case 'shoes':
        return ClothCategory.shoes;
      case 'accessory':
        return ClothCategory.accessory;
      default:
        return ClothCategory.top;
    }
  }

  static ClothWeather _weatherFrom(String? v) {
    switch (v) {
      case 'hot':
        return ClothWeather.hot;
      case 'cool':
        return ClothWeather.cool;
      case 'rain':
        return ClothWeather.rain;
      default:
        return ClothWeather.cool;
    }
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category.value,
        'color': color,
        'styles': styles.map((s) => s.value).toList(),
        'weather': weather.value,
        'imageUrl': imageUrl,
        'thumbUrl': thumbUrl,
        'lastWornAt':
            lastWornAt == null ? null : Timestamp.fromDate(lastWornAt!),
        'wearCount': wearCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ClothModel copyWith({
    String? name,
    ClothCategory? category,
    String? color,
    List<ClothStyle>? styles,
    ClothWeather? weather,
    String? imageUrl,
    String? thumbUrl,
    DateTime? lastWornAt,
    int? wearCount,
    DateTime? createdAt,
  }) {
    return ClothModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      styles: styles ?? this.styles,
      weather: weather ?? this.weather,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      lastWornAt: lastWornAt ?? this.lastWornAt,
      wearCount: wearCount ?? this.wearCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Extension publik untuk label warna (dipakai di banyak widget)
extension ClothModelLabels on ClothModel {
  String get colorLabel => ClothColor.label(color);
}
