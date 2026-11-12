import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/data/models/weather_model.dart';
import 'package:pakeaja/data/services/weather_service.dart';

/// State reaktif untuk kondisi cuaca & lokasi pengguna terkini.
class WeatherState {
  final WeatherData? data;
  final bool isLoading;
  final String? errorMessage;
  final WeatherIssueType? issueType;

  const WeatherState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.issueType,
  });

  bool get hasData => data != null;

  WeatherState copyWith({
    WeatherData? data,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    WeatherIssueType? issueType,
    bool clearIssueType = false,
  }) {
    return WeatherState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      issueType: clearIssueType ? null : (issueType ?? this.issueType),
    );
  }
}

/// Notifier untuk mengambil dan menyegarkan cuaca berdasarkan GPS/lokasi user.
class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherService _service;
  bool _inFlight = false;

  WeatherNotifier(
    this._service, {
    bool autoLoad = true,
  }) : super(WeatherState(isLoading: autoLoad)) {
    if (autoLoad) {
      Future.microtask(loadCurrentWeather);
    }
  }

  /// Memuat lokasi & cuaca terkini pengguna.
  Future<void> loadCurrentWeather() async {
    if (_inFlight) return;
    _inFlight = true;

    if (mounted) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearIssueType: true,
      );
    }

    try {
      final result = await _service.getCurrentWeather();
      if (!mounted) return;
      state = WeatherState(
        data: result,
        isLoading: false,
      );
    } on WeatherLocationException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        issueType: e.type,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat cuaca terkini.',
        issueType: WeatherIssueType.unavailable,
      );
    } finally {
      _inFlight = false;
    }
  }

  /// Alias eksplisit untuk pull-to-refresh atau tombol perbarui lokasi.
  Future<void> refresh() => loadCurrentWeather();
}

/// Provider global cuaca & lokasi terkini pengguna.
final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final service = ref.watch(weatherServiceProvider);
  return WeatherNotifier(service);
});

