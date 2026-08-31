import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// One day's forecast, as returned by Open-Meteo's `daily` block. Codes are
/// the WMO "weather interpretation codes" Open-Meteo documents at
/// https://open-meteo.com/en/docs — see [weatherIconFor]/[weatherDescription]
/// for how a raw code becomes something a human reads.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMaxC,
    required this.tempMinC,
    required this.precipitationProbability,
  });

  final DateTime date;
  final int weatherCode;

  /// Celsius — the unit Open-Meteo returns by default. Deliberately not
  /// converted to Fahrenheit here: this app also ships Finnish and Swedish
  /// localizations, where Celsius is the expected unit, and there's no
  /// per-user locale-to-unit mapping in place yet. If this app's audience
  /// turns out to be Fahrenheit-only, add `&temperature_unit=fahrenheit` to
  /// the request in WeatherService and drop the C suffix here.
  final double tempMaxC;
  final double tempMinC;

  /// 0-100 — Open-Meteo's daily maximum precipitation probability.
  final int precipitationProbability;

  /// True for a day where an outdoor plan is genuinely at risk: any
  /// drizzle/rain/snow/thunderstorm code, OR a precipitation chance of 60%
  /// or higher even under an otherwise-clear code. Used to badge outdoor
  /// events (see main.dart) rather than to hide anything — the family still
  /// decides, this just flags the day worth double-checking.
  bool get isOutdoorRisk =>
      precipitationProbability >= 60 || _rainOrSnowCodes.contains(weatherCode);

  factory DailyForecast.fromDailyBlock(Map<String, dynamic> daily, int index) {
    final times = daily['time'] as List<dynamic>;
    final codes = daily['weathercode'] as List<dynamic>;
    final maxTemps = daily['temperature_2m_max'] as List<dynamic>;
    final minTemps = daily['temperature_2m_min'] as List<dynamic>;
    final rainChance = daily['precipitation_probability_max'] as List<dynamic>?;

    return DailyForecast(
      date: DateTime.parse(times[index] as String),
      weatherCode: (codes[index] as num).toInt(),
      tempMaxC: (maxTemps[index] as num).toDouble(),
      tempMinC: (minTemps[index] as num).toDouble(),
      precipitationProbability: rainChance == null
          ? 0
          : ((rainChance[index] as num?)?.toInt() ?? 0),
    );
  }
}

const _rainOrSnowCodes = {
  51, 53, 55, 56, 57, // drizzle
  61, 63, 65, 66, 67, // rain
  71, 73, 75, 77, // snow
  80, 81, 82, // rain showers
  85, 86, // snow showers
  95, 96, 99, // thunderstorm
};

class WeatherIcon {
  const WeatherIcon(this.icon, this.color);
  final IconData icon;
  final Color color;
}

/// Icon + color for a WMO code, grouped into the same rough buckets any
/// weather app uses — nobody needs a day tile to visually distinguish
/// "slight drizzle" from "moderate drizzle".
WeatherIcon weatherIconFor(int code) {
  if (code == 0) return const WeatherIcon(Icons.wb_sunny, Colors.orange);
  if (code <= 2) {
    return const WeatherIcon(Icons.wb_cloudy, Colors.orangeAccent);
  }
  if (code == 3) return const WeatherIcon(Icons.cloud, Colors.blueGrey);
  if (code == 45 || code == 48) {
    // `Icons.foggy` is a newer Material Symbol not guaranteed present on
    // every Flutter SDK's generated Icons class — `dehaze` (stacked
    // horizontal lines) reads as "hazy" without that risk.
    return const WeatherIcon(Icons.dehaze, Colors.blueGrey);
  }
  if (code >= 71 && code <= 86) {
    return const WeatherIcon(Icons.ac_unit, Colors.lightBlue);
  }
  if (code >= 95) {
    return const WeatherIcon(Icons.thunderstorm, Colors.deepPurple);
  }
  if (_rainOrSnowCodes.contains(code)) {
    return const WeatherIcon(Icons.umbrella, Colors.blue);
  }
  return const WeatherIcon(Icons.cloud_outlined, Colors.blueGrey);
}

/// Short, localized description for a WMO code — used in the day-summary
/// line and the event rain-warning tooltip, so weather is never just an
/// icon with nothing behind it for a screen reader.
String weatherDescription(AppLocalizations l10n, int code) {
  if (code == 0) return l10n.weatherClear;
  if (code <= 2) return l10n.weatherPartlyCloudy;
  if (code == 3) return l10n.weatherOvercast;
  if (code == 45 || code == 48) return l10n.weatherFog;
  if (code == 51 || code == 53 || code == 55 || code == 56 || code == 57) {
    return l10n.weatherDrizzle;
  }
  if (code == 61 ||
      code == 63 ||
      code == 65 ||
      code == 66 ||
      code == 67 ||
      code == 80 ||
      code == 81 ||
      code == 82) {
    return l10n.weatherRain;
  }
  if (code == 71 ||
      code == 73 ||
      code == 75 ||
      code == 77 ||
      code == 85 ||
      code == 86) {
    return l10n.weatherSnow;
  }
  if (code == 95 || code == 96 || code == 99) return l10n.weatherThunderstorm;
  return l10n.weatherOvercast;
}
