import 'package:cloud_firestore/cloud_firestore.dart';

// Helper function to safely parse a string to a double, treating '-99' as null.
double? _parseDouble(String? value) {
  if (value == null || value == '-99') return null;
  return double.tryParse(value);
}

// Helper function to safely parse a string to an int, treating '-99' as null.
int? _parseInt(String? value) {
  if (value == null || value == '-99') return null;
  return int.tryParse(value);
}

class DailyHigh {
  final String? temperature;
  final String? time;

  DailyHigh({this.temperature, this.time});

  double? get temperatureAsDouble => _parseDouble(temperature);

  factory DailyHigh.fromMap(Map<String, dynamic> data) {
    return DailyHigh(
      temperature: data['temperature'] as String?,
      time: data['time'] as String?,
    );
  }
}

class DailyLow {
  final String? temperature;
  final String? time;

  DailyLow({this.temperature, this.time});

  double? get temperatureAsDouble => _parseDouble(temperature);

  factory DailyLow.fromMap(Map<String, dynamic> data) {
    return DailyLow(
      temperature: data['temperature'] as String?,
      time: data['time'] as String?,
    );
  }
}

class ObservationDetails {
  final DailyHigh? dailyHigh;
  final DailyLow? dailyLow;
  final String? humidity;
  final String? precipitation;
  final String? pressure;
  final String? temperature;
  final String? weather;
  final String? windDirection; // Angle
  final String? windSpeed; // m/s

  ObservationDetails({
    this.dailyHigh,
    this.dailyLow,
    this.humidity,
    this.precipitation,
    this.pressure,
    this.temperature,
    this.weather,
    this.windDirection,
    this.windSpeed,
  });

  int? get humidityAsInt => _parseInt(humidity);
  double? get precipitationAsDouble => _parseDouble(precipitation);
  double? get pressureAsDouble => _parseDouble(pressure);
  double? get temperatureAsDouble => _parseDouble(temperature);
  double? get windDirectionAsDouble => _parseDouble(windDirection);
  double? get windSpeedAsDouble => _parseDouble(windSpeed);

  factory ObservationDetails.fromMap(Map<String, dynamic> data) {
    return ObservationDetails(
      dailyHigh: data['dailyHigh'] != null ? DailyHigh.fromMap(data['dailyHigh']) : null,
      dailyLow: data['dailyLow'] != null ? DailyLow.fromMap(data['dailyLow']) : null,
      humidity: data['humidity'] as String?,
      precipitation: data['precipitation'] as String?,
      pressure: data['pressure'] as String?,
      temperature: data['temperature'] as String?,
      weather: data['weather'] as String?,
      windDirection: data['windDirection'] as String?,
      windSpeed: data['windSpeed'] as String?,
    );
  }
}

class ObservationData {
  final DateTime? createdAt;
  final String geohash;
  final String id;
  final double latitude;
  final double longitude;
  final ObservationDetails? observations;
  final String stationId;
  final String stationName;
  final int? timestamp;

  ObservationData({
    this.createdAt,
    required this.geohash,
    required this.id,
    required this.latitude,
    required this.longitude,
    this.observations,
    required this.stationId,
    required this.stationName,
    this.timestamp,
  });

  factory ObservationData.fromDocument(Map<String, dynamic> data, String docId) {
    return ObservationData(
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      geohash: data['geohash'] as String? ?? '',
      id: data['id'] as String? ?? docId,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      observations: data['observations'] != null ? ObservationDetails.fromMap(data['observations']) : null,
      stationId: data['stationId'] as String? ?? '',
      stationName: data['stationName'] as String? ?? '',
      timestamp: data['timestamp'] as int?,
    );
  }
}
