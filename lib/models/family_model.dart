import 'package:cloud_firestore/cloud_firestore.dart';

/// The family's shared weather-forecast location — a name for display plus
/// the coordinates Open-Meteo actually needs. Saved once by a parent in
/// Settings rather than read from device GPS: one family, one home base, no
/// extra location permission to request and justify (see WeatherService's
/// doc comment for the API choice behind this feature).
class FamilyWeatherLocation {
  const FamilyWeatherLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  factory FamilyWeatherLocation.fromMap(Map<String, dynamic> map) {
    return FamilyWeatherLocation(
      name: map['name'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'latitude': latitude, 'longitude': longitude};
  }
}

class FamilyModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final FamilyWeatherLocation? weatherLocation;

  FamilyModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.weatherLocation,
  });

  /// Builds a FamilyModel from a Firestore document snapshot's data map.
  factory FamilyModel.fromMap(Map<String, dynamic> data, String id) {
    final rawLocation = data['weather_location'];
    return FamilyModel(
      id: id,
      name: data['name'] ?? '',
      // Firestore timestamps come back as a Timestamp object, not DateTime,
      // so we convert it here. Falls back to "now" if missing.
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weatherLocation: rawLocation is Map
          ? FamilyWeatherLocation.fromMap(Map<String, dynamic>.from(rawLocation))
          : null,
    );
  }

  /// Converts this object back into a map, ready to write to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'created_at': createdAt,
      'weather_location': weatherLocation?.toMap(),
    };
  }
}
