import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

/// One geocoding candidate — a typed place name is ambiguous ("Springfield"
/// exists in a dozen US states), so the caller shows a short list of these
/// for the user to pick the right one rather than guessing the first match.
class WeatherLocationResult {
  const WeatherLocationResult({
    required this.name,
    required this.admin1,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String name;

  /// State/region — empty for places where Open-Meteo's geocoder doesn't
  /// return one (small countries, some non-US results).
  final String admin1;
  final String country;
  final double latitude;
  final double longitude;

  /// What the search results list shows, and what gets saved as the
  /// family's location name — e.g. "Austin, Texas, United States".
  String get displayName =>
      [name, if (admin1.isNotEmpty) admin1, country].join(', ');
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);
  final String message;
  @override
  String toString() => 'WeatherServiceException($message)';
}

/// Wraps Open-Meteo (https://open-meteo.com) for both geocoding and the
/// daily forecast. Chosen deliberately over a key-based provider (OpenWeather,
/// WeatherAPI, etc.) after this project's earlier Firebase Storage/Blaze
/// surprise: Open-Meteo needs no account, no billing, and no API key to
/// generate, ship in the app, or eventually rotate — just an HTTP GET. Its
/// free tier's rate limit (10,000 calls/day) is far beyond what one family's
/// app will ever produce.
class WeatherService {
  static const _geocodeUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _forecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _requestTimeout = Duration(seconds: 10);

  Future<List<WeatherLocationResult>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(_geocodeUrl).replace(
      queryParameters: {'name': trimmed, 'count': '5', 'language': 'en'},
    );

    final http.Response response;
    try {
      response = await http.get(uri).timeout(_requestTimeout);
    } catch (_) {
      throw const WeatherServiceException('geocoding-network-error');
    }

    if (response.statusCode != 200) {
      throw const WeatherServiceException('geocoding-failed');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>?;
    if (results == null) return const [];

    return results.map((r) {
      final map = r as Map<String, dynamic>;
      return WeatherLocationResult(
        name: map['name'] as String? ?? '',
        admin1: map['admin1'] as String? ?? '',
        country: map['country'] as String? ?? '',
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  /// 7-day forecast for a fixed point. `forecast_days: 7` keeps the payload
  /// small and matches the horizon the calendar actually shows meaningfully
  /// far ahead — Open-Meteo supports more, but a family isn't planning
  /// outdoor activities two weeks out from a forecast anyway.
  Future<List<DailyForecast>> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'daily':
            'weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    final http.Response response;
    try {
      response = await http.get(uri).timeout(_requestTimeout);
    } catch (_) {
      throw const WeatherServiceException('forecast-network-error');
    }

    if (response.statusCode != 200) {
      throw const WeatherServiceException('forecast-failed');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = body['daily'] as Map<String, dynamic>?;
    if (daily == null) return const [];

    final times = daily['time'] as List<dynamic>;
    return List.generate(
      times.length,
      (i) => DailyForecast.fromDailyBlock(daily, i),
    );
  }
}
