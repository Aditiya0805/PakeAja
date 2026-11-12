import 'package:flutter/material.dart';
import 'package:pakeaja/data/models/cloth_model.dart';

/// Jenis kendala saat mengambil lokasi atau cuaca pengguna.
enum WeatherIssueType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  networkError,
  unavailable,
}

/// Exception terstruktur untuk kegagalan pengambilan lokasi / cuaca.
class WeatherLocationException implements Exception {
  final WeatherIssueType type;
  final String message;

  const WeatherLocationException(this.type, this.message);

  @override
  String toString() => message;
}

/// Representasi data cuaca & lokasi terkini pengguna.
class WeatherData {
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final double windSpeedKmh;
  final int weatherCode;
  final String conditionLabel;
  final String emoji;
  final String locationName;
  final double latitude;
  final double longitude;
  final bool isDay;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeedKmh,
    required this.weatherCode,
    required this.conditionLabel,
    required this.emoji,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.isDay = true,
    required this.fetchedAt,
  });

  int get roundedTemp => temperatureC.round();
  int get roundedFeelsLike => feelsLikeC.round();
  String get tempText => '$roundedTemp°C';

  bool get isRainy => weatherCode >= 51 && weatherCode <= 99 && !_isSnowCode(weatherCode);

  static bool _isSnowCode(int code) =>
      (code >= 71 && code <= 77) || code == 85 || code == 86;

  /// Pemetaan kondisi cuaca ke kategori `ClothWeather` PakeAja.
  ClothWeather get clothWeather {
    if (isRainy) return ClothWeather.rain;
    if (temperatureC >= 27.0) return ClothWeather.hot;
    return ClothWeather.cool;
  }

  /// Ikon Material yang selaras dengan kondisi cuaca terkini.
  IconData get iconData {
    if (weatherCode == 95 || weatherCode == 96 || weatherCode == 99) {
      return Icons.thunderstorm_rounded;
    }
    if (isRainy) return Icons.umbrella_rounded;
    if (_isSnowCode(weatherCode)) return Icons.ac_unit_rounded;
    if (weatherCode == 45 || weatherCode == 48) return Icons.foggy;
    if (weatherCode == 3) return Icons.cloud_rounded;
    if (weatherCode == 1 || weatherCode == 2) {
      return isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded;
    }
    return isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
  }

  /// Saran busana singkat 1 baris untuk kartu Beranda.
  String get shortAdvice {
    if (weatherCode == 95 || weatherCode == 96 || weatherCode == 99) {
      return 'Waspada badai petir—pakai jaket tahan air & sepatu tertutup.';
    }
    if (isRainy) {
      return 'Siapkan jaket tahan air atau payung & hindari bahan mudah basah.';
    }
    if (temperatureC >= 31) {
      return 'Cuaca cukup terik—pilih kaus katun tipis atau linen sejuk.';
    }
    if (temperatureC >= 27) {
      return 'Cocok untuk kemeja katun ringan, kaus breathable, atau celana linen.';
    }
    if (temperatureC >= 22) {
      return 'Cuaca sejuk nyaman—padu-padankan kemeja atau outer tipis.';
    }
    return 'Udara cukup dingin—gunakan jaket, sweater, atau outer hangat.';
  }

  /// Saran busana lengkap untuk modal detail cuaca.
  String get detailedAdvice {
    final base = isRainy
        ? 'Terpantau ${conditionLabel.toLowerCase()} di $locationName dengan kelembapan $humidity%. Prioritaskan sepatu anti-slip, celana tidak terlalu panjang, serta outer atau jas hujan.'
        : temperatureC >= 30
            ? 'Suhu terasa $roundedFeelsLike°C dengan kondisi ${conditionLabel.toLowerCase()}. Pilih bahan katun, rayon, atau linen berwarna cerah agar sirkulasi udara tetap sejuk.'
            : temperatureC >= 26
                ? 'Suhu sekitar $roundedTemp°C (terasa $roundedFeelsLike°C) dengan kelembapan $humidity%. Sangat pas mengenakan kemeja katun sejuk, kaus santai, atau celana chino ringan.'
                : 'Udara terasa sejuk ($roundedTemp°C, terasa $roundedFeelsLike°C) dengan angin ${windSpeedKmh.round()} km/j. Disarankan menambahkan cardigan, hoodie, atau jaket ringan.';
    return base;
  }

  /// Terjemahkan kode WMO Open-Meteo menjadi label Bahasa Indonesia & emoji.
  static ({String label, String emoji}) describeWmoCode(
    int code, {
    bool isDay = true,
  }) {
    if (code == 0) {
      return (
        label: isDay ? 'Cerah' : 'Cerah Malam',
        emoji: isDay ? '☀️' : '🌙',
      );
    }
    if (code == 1 || code == 2) {
      return (
        label: isDay ? 'Cerah Berawan' : 'Berawan Malam',
        emoji: isDay ? '⛅' : '☁️',
      );
    }
    if (code == 3) {
      return const (label: 'Berawan', emoji: '☁️');
    }
    if (code == 45 || code == 48) {
      return const (label: 'Berkabut', emoji: '🌫️');
    }
    if (code == 51 || code == 53 || code == 55 || code == 56 || code == 57) {
      return const (label: 'Gerimis', emoji: '🌦️');
    }
    if (code == 61 || code == 80) {
      return const (label: 'Hujan Ringan', emoji: '🌦️');
    }
    if (code == 63 || code == 81) {
      return const (label: 'Hujan Sedang', emoji: '🌧️');
    }
    if (code == 65 || code == 66 || code == 67 || code == 82) {
      return const (label: 'Hujan Lebat', emoji: '⛈️');
    }
    if (_isSnowCode(code)) {
      return const (label: 'Bersalju', emoji: '❄️');
    }
    if (code == 95 || code == 96 || code == 99) {
      return const (label: 'Badai Petir', emoji: '⛈️');
    }
    return const (label: 'Berawan', emoji: '🌤️');
  }
}
