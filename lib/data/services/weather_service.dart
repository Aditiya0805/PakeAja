import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pakeaja/data/models/weather_model.dart';

typedef PositionCoordinates = ({double latitude, double longitude});
typedef PositionLoader = Future<PositionCoordinates> Function();

/// Service untuk mengambil lokasi terkini user (GPS / Geolocation browser)
/// serta cuaca real-time tanpa membutuhkan API Key rahasia (Open-Meteo + BigDataCloud).
class WeatherService {
  final http.Client _client;
  final PositionLoader? _customPositionLoader;

  WeatherService({
    http.Client? client,
    PositionLoader? positionLoader,
  })  : _client = client ?? http.Client(),
        _customPositionLoader = positionLoader;

  /// Mengambil koordinat lokasi, nama daerah (reverse geocoding), dan cuaca terkini.
  Future<WeatherData> getCurrentWeather() async {
    final coords = await _resolveCoordinates();

    final results = await Future.wait([
      _fetchOpenMeteo(coords.latitude, coords.longitude),
      _reverseGeocodeLocationName(coords.latitude, coords.longitude),
    ]);

    final weatherJson = results[0] as Map<String, dynamic>;
    final locationName = results[1] as String;

    return parseOpenMeteoResponse(
      weatherJson,
      latitude: coords.latitude,
      longitude: coords.longitude,
      locationName: locationName,
    );
  }

  /// Mendapatkan koordinat user dengan pengecekan layanan lokasi & izin.
  Future<PositionCoordinates> _resolveCoordinates() async {
    final customLoader = _customPositionLoader;
    if (customLoader != null) {
      return customLoader();
    }

    try {
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw const WeatherLocationException(
            WeatherIssueType.serviceDisabled,
            'Layanan lokasi (GPS) sedang nonaktif. Aktifkan GPS untuk melihat cuaca di lokasimu.',
          );
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const WeatherLocationException(
          WeatherIssueType.permissionDenied,
          'Izin lokasi belum diberikan. Ketuk untuk mengizinkan akses lokasi.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const WeatherLocationException(
          WeatherIssueType.permissionDeniedForever,
          'Izin lokasi diblokir. Aktifkan izin lokasi di pengaturan aplikasi/browser.',
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } on TimeoutException {
        if (!kIsWeb) {
          position = await Geolocator.getLastKnownPosition();
        }
        if (position == null) rethrow;
      }

      return (latitude: position.latitude, longitude: position.longitude);
    } on WeatherLocationException {
      rethrow;
    } on MissingPluginException {
      throw const WeatherLocationException(
        WeatherIssueType.unavailable,
        'Layanan lokasi belum tersedia di perangkat ini.',
      );
    } on UnimplementedError {
      throw const WeatherLocationException(
        WeatherIssueType.unavailable,
        'Layanan lokasi belum didukung di platform ini.',
      );
    } on LocationServiceDisabledException {
      throw const WeatherLocationException(
        WeatherIssueType.serviceDisabled,
        'Layanan lokasi (GPS) sedang nonaktif. Aktifkan GPS lalu muat ulang.',
      );
    } on PermissionDeniedException {
      throw const WeatherLocationException(
        WeatherIssueType.permissionDenied,
        'Izin lokasi ditolak oleh sistem/browser.',
      );
    } catch (e) {
      throw WeatherLocationException(
        WeatherIssueType.unavailable,
        'Gagal mendapatkan lokasi terkini: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _fetchOpenMeteo(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m',
      'timezone': 'auto',
    });

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw WeatherLocationException(
          WeatherIssueType.networkError,
          'Server cuaca mengembalikan status ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherLocationException(
          WeatherIssueType.networkError,
          'Format data cuaca tidak valid.',
        );
      }
      return decoded;
    } on WeatherLocationException {
      rethrow;
    } catch (_) {
      throw const WeatherLocationException(
        WeatherIssueType.networkError,
        'Tidak dapat terhubung ke layanan cuaca. Periksa koneksi internetmu.',
      );
    }
  }

  Future<String> _reverseGeocodeLocationName(double lat, double lon) async {
    final fallback = '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': lat.toStringAsFixed(4),
          'longitude': lon.toStringAsFixed(4),
          'localityLanguage': 'id',
        },
      );
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return fallback;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return fallback;

      return formatLocationName(decoded, fallback: fallback);
    } catch (_) {
      return fallback;
    }
  }

  /// Parsing JSON dari Open-Meteo `current` response.
  static WeatherData parseOpenMeteoResponse(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
    required String locationName,
    DateTime? fetchedAt,
  }) {
    final current = json['current'] as Map<String, dynamic>? ?? {};

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
    final feelsLike =
        (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 70;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = ((current['is_day'] as num?)?.toInt() ?? 1) == 1;

    final described = WeatherData.describeWmoCode(code, isDay: isDay);

    return WeatherData(
      temperatureC: temp,
      feelsLikeC: feelsLike,
      humidity: humidity,
      windSpeedKmh: wind,
      weatherCode: code,
      conditionLabel: described.label,
      emoji: described.emoji,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      isDay: isDay,
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  /// Membentuk nama wilayah singkat yang rapi dari respon reverse-geocoding.
  static String formatLocationName(
    Map<String, dynamic> json, {
    String fallback = 'Lokasi Terkini',
  }) {
    final locality = (json['locality'] as String?)?.trim() ?? '';
    final city = (json['city'] as String?)?.trim() ?? '';
    final subdivision =
        (json['principalSubdivision'] as String?)?.trim() ?? '';
    final country = (json['countryName'] as String?)?.trim() ?? '';

    final parts = <String>[];
    void addIfUnique(String candidate) {
      if (candidate.isEmpty) return;
      final lower = candidate.toLowerCase();
      if (parts.any((p) => p.toLowerCase() == lower)) return;
      parts.add(candidate);
    }

    addIfUnique(locality);
    addIfUnique(city);
    if (parts.length < 2) addIfUnique(subdivision);
    if (parts.isEmpty) addIfUnique(country);

    if (parts.isEmpty) return fallback;
    return parts.take(2).join(', ');
  }
}
