import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'package:timezone/timezone.dart' as tz;

// A helper function to safely parse a DateTime from various potential data types,
// and correctly interpret it in the Taipei timezone.
DateTime _parseDateTimeSafely(dynamic value) {
  if (value == null) {
    // If the value is null, return the current time in Taipei as a fallback.
    return tz.TZDateTime.now(tz.getLocation('Asia/Taipei'));
  }

  // Define the Taipei location for timezone conversion.
  final location = tz.getLocation('Asia/Taipei');

  if (value is Timestamp) {
    // Firestore Timestamps are timezone-aware (UTC). Convert it to a TZDateTime in Taipei.
    return tz.TZDateTime.from(value.toDate(), location);
  }

  if (value is String) {
    try {
      // First, parse the string into a standard Dart DateTime object.
      // This object will internally be in UTC but will remember the offset (+08:00).
      final parsedDateTime = DateTime.parse(value);
      // Then, create a TZDateTime from it, correctly interpreting it in the Taipei location.
      // This ensures that .year, .month, .day will always refer to the Taipei calendar date.
      return tz.TZDateTime.from(parsedDateTime, location);
    } catch (e) {
      // If parsing fails, return the current time in Taipei as a fallback.
      log('Could not parse date string: $value. Error: $e', name: 'DateTimeParsing');
      return tz.TZDateTime.now(location);
    }
  }

  // As a final fallback, return the current time in Taipei.
  return tz.TZDateTime.now(location);
}


class LocationData {
  final double latitude;
  final double longitude;
  final int timestamp;
  final String townName;
  final DateTime updatedAt;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.townName,
    required this.updatedAt,
  });

  factory LocationData.fromMap(Map<String, dynamic> data) {
    return LocationData(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as num?)?.toInt() ?? 0,
      townName: data['townName'] as String? ?? '',
      updatedAt: _parseDateTimeSafely(data['updatedAt']),
    );
  }
}

class Forecast { // Represents a single hourly forecast item
  final double? temp;
  final double? apparentTemperature;
  final String comfort;
  final DateTime endTime;
  final String humidity;
  final double? maxTemp;
  final double? minTemp;
  final String rainProb;
  final DateTime startTime;
  final int timestamp;
  final String weather;
  final String windDirection;
  final double? windSpeed;

  Forecast({
    this.temp,
    this.apparentTemperature,
    required this.comfort,
    required this.endTime,
    required this.humidity,
    this.maxTemp,
    this.minTemp,
    required this.rainProb,
    required this.startTime,
    required this.timestamp,
    required this.weather,
    required this.windDirection,
    required this.windSpeed,
  });

  factory Forecast.fromMap(Map<String, dynamic> data) {
    return Forecast(
      temp: (data['Temp'] as num?)?.toDouble(),
      apparentTemperature: (data['apparent_temperature'] as num?)?.toDouble(),
      comfort: data['comfort'] as String? ?? '',
      endTime: _parseDateTimeSafely(data['endTime']),
      humidity: data['humidity'] as String? ?? '',
      maxTemp: (data['maxTemp'] as num?)?.toDouble(),
      minTemp: (data['minTemp'] as num?)?.toDouble(),
      rainProb: data['rainProb'] as String? ?? '',
      startTime: _parseDateTimeSafely(data['startTime']),
      timestamp: (data['timestamp'] as num?)?.toInt() ?? 0,
      weather: data['weather'] as String? ?? '',
      windDirection: data['windDirection'] as String? ?? '',
      windSpeed: (data['windSpeed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeeklyForecastItem { // Represents a single daily forecast item
  final String comfort;
  final DateTime endTime;
  final String humidity;
  final double? maxTemp;
  final double? minTemp;
  final double? maxApparentTemperature;
  final double? minApparentTemperature;
  final String? rainProb;
  final DateTime startTime;
  final int timestamp;
  final String weather;
  final String windDirection;
  final double? windSpeed;

  WeeklyForecastItem({
    required this.comfort,
    required this.endTime,
    required this.humidity,
    required this.maxTemp,
    required this.minTemp,
    this.maxApparentTemperature,
    this.minApparentTemperature,
    this.rainProb,
    required this.startTime,
    required this.timestamp,
    required this.weather,
    required this.windDirection,
    required this.windSpeed,
  });

  factory WeeklyForecastItem.fromMap(Map<String, dynamic> data) {
    return WeeklyForecastItem(
      comfort: data['comfort'] as String? ?? '',
      endTime: _parseDateTimeSafely(data['endTime']),
      humidity: data['humidity'] as String? ?? '',
      maxTemp: (data['maxTemp'] as num?)?.toDouble(),
      minTemp: (data['minTemp'] as num?)?.toDouble(),
      maxApparentTemperature: (data['max_apparent_temperature'] as num?)?.toDouble(),
      minApparentTemperature: (data['min_apparent_temperature'] as num?)?.toDouble(),
      rainProb: data['rainProb'] as String?,
      startTime: _parseDateTimeSafely(data['startTime']),
      timestamp: (data['timestamp'] as num?)?.toInt() ?? 0,
      weather: data['weather'] as String? ?? '',
      windDirection: data['windDirection'] as String? ?? '',
      windSpeed: (data['windSpeed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Main weather forecast model
class WeatherForecast {
  final String id;
  final String countyName;
  final LocationData location;
  final DateTime updatedAt;
  final List<Forecast> hourlyForecasts;
  final List<WeeklyForecastItem> weeklyForecasts;

  WeatherForecast({
    required this.id,
    required this.countyName,
    required this.location,
    required this.updatedAt,
    required this.hourlyForecasts,
    required this.weeklyForecasts,
  });

  factory WeatherForecast.fromDocument(Map<String, dynamic> data, String id) {
    List<Forecast> parsedHourly = [];
    if (data['hourly_forecast'] != null && data['hourly_forecast'] is List) {
      for (var forecastMap in data['hourly_forecast']) {
        if (forecastMap is Map<String, dynamic>) {
          parsedHourly.add(Forecast.fromMap(forecastMap));
        }
      }
    }

    List<WeeklyForecastItem> parsedWeekly = [];
    if (data['weekly_forecast'] != null && data['weekly_forecast'] is List) {
      for (var forecastMap in data['weekly_forecast']) {
        if (forecastMap is Map<String, dynamic>) {
          parsedWeekly.add(WeeklyForecastItem.fromMap(forecastMap));
        }
      }
    }
    
    final countyNameValue = data['countyName'] as String? ?? '';
    final locationValue = data['location'] != null 
        ? LocationData.fromMap(data['location'] as Map<String, dynamic>)
        : LocationData(latitude: 0.0, longitude: 0.0, timestamp: 0, townName: '', updatedAt: DateTime.now());
    final updatedAtValue = _parseDateTimeSafely(data['updatedAt']);
    
    return WeatherForecast(
      id: id,
      countyName: countyNameValue,
      location: locationValue,
      updatedAt: updatedAtValue,
      hourlyForecasts: parsedHourly,
      weeklyForecasts: parsedWeekly,
    );
  }
}
