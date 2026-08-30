import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_model.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'auth_provider.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// The family's saved forecast location, or null if a parent hasn't set one
/// yet. Rides on currentFamilyProvider (already fetched for Settings) rather
/// than opening a second Firestore listener for one field.
final weatherLocationProvider = Provider<FamilyWeatherLocation?>((ref) {
  return ref.watch(currentFamilyProvider).valueOrNull?.weatherLocation;
});

/// 7-day forecast for the family's saved location. `autoDispose` so it
/// re-fetches with fresh data after the calendar has been away for a while,
/// rather than serving an hours-stale forecast for the rest of the session.
///
/// Deliberately swallows network/API errors into a null result instead of
/// surfacing an AsyncError — weather is a nice-to-have layered on top of the
/// calendar, and a flaky connection should never block or error out the
/// calendar screen itself. Emits null (not an error) when no location is
/// set yet, too, so callers can't tell "no location" apart from "fetch
/// failed" — both mean "don't show weather right now", which is the only
/// distinction the UI actually needs to make.
final weatherForecastProvider =
    FutureProvider.autoDispose<List<DailyForecast>?>((ref) async {
      final location = ref.watch(weatherLocationProvider);
      if (location == null) return null;

      final service = ref.watch(weatherServiceProvider);
      try {
        return await service.getForecast(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } catch (_) {
        return null;
      }
    });
