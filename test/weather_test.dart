import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/weather_model.dart';
import 'package:pakeaja/data/services/weather_service.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/home/presentation/screens/home_screen.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:pakeaja/features/weather/providers/weather_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('WeatherData & WMO mapping', () {
    test('maps clear, rain, and night WMO codes accurately', () {
      expect(
        WeatherData.describeWmoCode(0, isDay: true),
        (label: 'Cerah', emoji: '☀️'),
      );
      expect(
        WeatherData.describeWmoCode(0, isDay: false),
        (label: 'Cerah Malam', emoji: '🌙'),
      );
      expect(
        WeatherData.describeWmoCode(61),
        (label: 'Hujan Ringan', emoji: '🌦️'),
      );
      expect(
        WeatherData.describeWmoCode(95),
        (label: 'Badai Petir', emoji: '⛈️'),
      );
    });

    test('maps weather conditions to ClothWeather categories', () {
      final hotWeather = WeatherData(
        temperatureC: 31.2,
        feelsLikeC: 34.0,
        humidity: 68,
        windSpeedKmh: 9.0,
        weatherCode: 0,
        conditionLabel: 'Cerah',
        emoji: '☀️',
        locationName: 'Surabaya',
        latitude: -7.25,
        longitude: 112.75,
        fetchedAt: DateTime(2026),
      );
      expect(hotWeather.clothWeather, ClothWeather.hot);

      final coolWeather = WeatherData(
        temperatureC: 23.4,
        feelsLikeC: 23.0,
        humidity: 72,
        windSpeedKmh: 12.0,
        weatherCode: 2,
        conditionLabel: 'Cerah Berawan',
        emoji: '⛅',
        locationName: 'Malang',
        latitude: -7.98,
        longitude: 112.63,
        fetchedAt: DateTime(2026),
      );
      expect(coolWeather.clothWeather, ClothWeather.cool);

      final rainyWeather = WeatherData(
        temperatureC: 29.0,
        feelsLikeC: 30.0,
        humidity: 88,
        windSpeedKmh: 15.0,
        weatherCode: 63,
        conditionLabel: 'Hujan Sedang',
        emoji: '🌧️',
        locationName: 'Bogor',
        latitude: -6.60,
        longitude: 106.80,
        fetchedAt: DateTime(2026),
      );
      expect(rainyWeather.clothWeather, ClothWeather.rain);
    });
  });

  group('WeatherService', () {
    test('fetches weather from Open-Meteo and location from reverse geocoding',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 24.6,
                'relative_humidity_2m': 82,
                'apparent_temperature': 25.1,
                'is_day': 1,
                'weather_code': 61,
                'wind_speed_10m': 11.4,
              },
            }),
            200,
          );
        }
        if (request.url.host == 'api.bigdatacloud.net') {
          return http.Response(
            jsonEncode({
              'locality': 'Coblong',
              'city': 'Kota Bandung',
              'principalSubdivision': 'Jawa Barat',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = WeatherService(
        client: mockClient,
        positionLoader: () async => (latitude: -6.8915, longitude: 107.6107),
      );

      final result = await service.getCurrentWeather();

      expect(result.roundedTemp, 25);
      expect(result.conditionLabel, 'Hujan Ringan');
      expect(result.emoji, '🌦️');
      expect(result.locationName, 'Coblong, Kota Bandung');
      expect(result.humidity, 82);
      expect(result.clothWeather, ClothWeather.rain);
    });

    test('WeatherNotifier populates state and handles errors gracefully',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 29.8,
                'relative_humidity_2m': 65,
                'apparent_temperature': 32.0,
                'is_day': 1,
                'weather_code': 0,
                'wind_speed_10m': 8.2,
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({'city': 'Yogyakarta', 'principalSubdivision': 'DIY'}),
          200,
        );
      });

      final service = WeatherService(
        client: mockClient,
        positionLoader: () async => (latitude: -7.7956, longitude: 110.3695),
      );

      final notifier = WeatherNotifier(service, autoLoad: false);
      await notifier.loadCurrentWeather();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.data?.locationName, 'Yogyakarta, DIY');
      expect(notifier.state.data?.tempText, '30°C');

      final failingService = WeatherService(
        client: MockClient((_) async => http.Response('error', 500)),
        positionLoader: () async => throw const WeatherLocationException(
          WeatherIssueType.permissionDenied,
          'Izin lokasi ditolak.',
        ),
      );
      final failNotifier = WeatherNotifier(failingService, autoLoad: false);
      await failNotifier.loadCurrentWeather();

      expect(failNotifier.state.hasData, isFalse);
      expect(failNotifier.state.issueType, WeatherIssueType.permissionDenied);
      expect(failNotifier.state.errorMessage, 'Izin lokasi ditolak.');
    });
  });

  group('HomeScreen weather UI integration', () {
    testWidgets('displays real location and weather from weatherServiceProvider',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 23.0,
                'relative_humidity_2m': 85,
                'apparent_temperature': 24.0,
                'is_day': 1,
                'weather_code': 61,
                'wind_speed_10m': 14.0,
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'locality': 'Dago',
            'city': 'Bandung',
          }),
          200,
        );
      });

      final weatherService = WeatherService(
        client: mockClient,
        positionLoader: () async => (latitude: -6.88, longitude: 107.61),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weatherServiceProvider.overrideWithValue(weatherService),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            userDataProvider.overrideWith((ref) => Stream.value(null)),
            clothesListProvider.overrideWith((ref) => Stream.value([])),
            outfitHistoryProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('23°C  Hujan Ringan'), findsOneWidget);
      expect(find.text('Dago, Bandung'), findsOneWidget);
      expect(find.text('Jakarta Selatan'), findsNothing);

      // Tap weather badge card to open detail modal
      await tester.tap(find.text('23°C  Hujan Ringan'));
      await tester.pumpAndSettle();

      expect(find.text('Cuaca & Saran Busana'), findsOneWidget);
      expect(
        find.text('Lokasi: Dago, Bandung (23°C - Hujan Ringan)'),
        findsOneWidget,
      );
      expect(find.text('Kelembapan 85%'), findsOneWidget);
      expect(find.text('Angin 14 km/j'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

