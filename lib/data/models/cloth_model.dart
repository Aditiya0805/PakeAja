import 'package:cloud_firestore/cloud_firestore.dart';

enum ClothCategory {
  top('top', 'Atasan'),
  bottom('bottom', 'Bawahan'),
  onepiece('onepiece', 'One-piece'),
  outer('outer', 'Outer'),
  shoes('shoes', 'Sepatu'),
  accessory('accessory', 'Aksesori');

  final String value;
  final String label;

  const ClothCategory(this.value, this.label);
}

enum ClothStyle {
  casual('casual', 'Casual'),
  formal('formal', 'Formal'),
  semiFormal('semi-formal', 'Semi-formal'),
  sport('sport', 'Sport');

  final String value;
  final String label;

  const ClothStyle(this.value, this.label);

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

extension ClothStyleExt on ClothStyle {
  static ClothStyle fromValue(String v) => ClothStyle.fromValue(v);
}

enum ClothWeather {
  hot('hot', 'Panas'),
  cool('cool', 'Sejuk'),
  rain('rain', 'Hujan');

  final String value;
  final String label;

  const ClothWeather(this.value, this.label);
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

    List<ClothStyle> parseStyles(dynamic stylesData) {
      if (stylesData is List) {
        return stylesData
            .map((s) => ClothStyle.fromValue(s.toString()))
            .toList();
      } else if (stylesData is String) {
        return [ClothStyle.fromValue(stylesData)];
      }
      return [ClothStyle.casual];
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return ClothModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: _categoryFrom(data['category'] as String?),
      color: data['color'] as String? ?? ClothColor.other,
      styles: parseStyles(data['styles']),
      weather: _weatherFrom(data['weather'] as String?),
      imageUrl: data['imageUrl'] as String? ?? '',
      thumbUrl: data['thumbUrl'] as String?,
      lastWornAt: parseDate(data['lastWornAt']),
      wearCount: (data['wearCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
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
    String? id,
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
      id: id ?? this.id,
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
