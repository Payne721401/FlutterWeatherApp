import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer'; // Import for log

// Helper function to safely parse DateTime from dynamic (String or Timestamp)
DateTime _parseDateTimeSafely(dynamic value) {
  if (value == null) {
    return DateTime.now(); // Default to current time if null
  } else if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now(); // Try parsing string, default to now if invalid
  }
  log('WARNING: Unexpected type for DateTime field: ${value.runtimeType}. Value: $value', name: 'WeatherModelDebug');
  return DateTime.now(); // Fallback for unexpected types
}

// 代表每個鄉鎮文件中的 location 資訊
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
    log('LocationData.fromMap - Raw data: $data', name: 'WeatherModelDebug');
    final latitudeValue = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitudeValue = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final timestampValue = (data['timestamp'] as num?)?.toInt() ?? 0;

    // Logging and safe access for townName
    if (data['townName'] == null) {
      log('WARNING: LocationData.fromMap - townName is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final townNameValue = data['townName'] as String? ?? ''; 
    
    final updatedAtValue = _parseDateTimeSafely(data['updatedAt']); // Using helper

    log('LocationData.fromMap - Parsed: latitude=$latitudeValue, longitude=$longitudeValue, timestamp=$timestampValue, townName=$townNameValue, updatedAt=$updatedAtValue', name: 'WeatherModelDebug');

    return LocationData(
      latitude: latitudeValue,
      longitude: longitudeValue,
      timestamp: timestampValue,
      townName: townNameValue,
      updatedAt: updatedAtValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'townName': townName,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// 代表每個鄉鎮文件中的 forecasts 陣列中的每個3小時預報項目
class Forecast {
  final double? temp; // MODIFIED: Changed to double?
  final String comfort; // Non-nullable
  final DateTime endTime;
  final String humidity; // Non-nullable
  final double? maxTemp; // MODIFIED: Changed to double?
  final double? minTemp; // MODIFIED: Changed to double?
  final String rainProb; // Non-nullable
  final DateTime startTime;
  final int timestamp;
  final String weather; // Non-nullable
  final String windDirection; // Non-nullable
  final double? windSpeed; // MODIFIED: Changed to double?

  Forecast({
    this.temp,
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
    log('Forecast.fromMap - Raw data: $data', name: 'WeatherModelDebug');
    final tempValue = (data['Temp'] as num?)?.toDouble(); // MODIFIED: Use .toDouble()

    // Logging and safe access for comfort
    if (data['comfort'] == null) {
      log('WARNING: Forecast.fromMap - comfort is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final comfortValue = data['comfort'] as String? ?? ''; 

    final endTimeValue = _parseDateTimeSafely(data['endTime']); // Using helper for endTime

    // Logging and safe access for humidity
    if (data['humidity'] == null) {
      log('WARNING: Forecast.fromMap - humidity is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final humidityValue = data['humidity'] as String? ?? ''; 

    final maxTempValue = (data['maxTemp'] as num?)?.toDouble(); // MODIFIED: Use .toDouble()
    final minTempValue = (data['minTemp'] as num?)?.toDouble(); // MODIFIED: Use .toDouble()

    // Logging and safe access for rainProb
    if (data['rainProb'] == null) {
      log('WARNING: Forecast.fromMap - rainProb is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final rainProbValue = data['rainProb'] as String? ?? ''; 

    final startTimeValue = _parseDateTimeSafely(data['startTime']); // Using helper for startTime

    final timestampValue = (data['timestamp'] as num?)?.toInt() ?? 0;

    // Logging and safe access for weather
    if (data['weather'] == null) {
      log('WARNING: Forecast.fromMap - weather is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final weatherValue = data['weather'] as String? ?? ''; 

    // Logging and safe access for windDirection
    if (data['windDirection'] == null) {
      log('WARNING: Forecast.fromMap - windDirection is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final windDirectionValue = data['windDirection'] as String? ?? ''; 

    // Logging and safe access for windSpeed
    if (data['windSpeed'] == null) {
      log('WARNING: Forecast.fromMap - windSpeed is null in raw data. Using default 0.', name: 'WeatherModelDebug');
    }
    final windSpeedValue = (data['windSpeed'] as num?)?.toDouble() ?? 0.0; // MODIFIED: Use .toDouble() and default 0.0

    log('Forecast.fromMap - Parsed: temp=$tempValue, comfort=$comfortValue, endTime=$endTimeValue, humidity=$humidityValue, maxTemp=$maxTempValue, minTemp=$minTempValue, rainProb=$rainProbValue, startTime=$startTimeValue, timestamp=$timestampValue, weather=$weatherValue, windDirection=$windDirectionValue, windSpeed=$windSpeedValue', name: 'WeatherModelDebug');

    return Forecast(
      temp: tempValue,
      comfort: comfortValue,
      endTime: endTimeValue,
      humidity: humidityValue,
      maxTemp: maxTempValue,
      minTemp: minTempValue,
      rainProb: rainProbValue,
      startTime: startTimeValue,
      timestamp: timestampValue,
      weather: weatherValue,
      windDirection: windDirectionValue,
      windSpeed: windSpeedValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (temp != null) 'Temp': temp,
      'comfort': comfort,
      'endTime': endTime.toIso8601String(),
      'humidity': humidity,
      if (maxTemp != null) 'maxTemp': maxTemp,
      if (minTemp != null) 'minTemp': minTemp,
      'rainProb': rainProb,
      'startTime': startTime.toIso8601String(),
      'timestamp': timestamp,
      'weather': weather,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
    };
  }
}

// 代表 weekly 子集合中 forecasts 陣列的每個項目
class WeeklyForecastItem {
  final String comfort; // Non-nullable
  final DateTime endTime;
  final String humidity; // Non-nullable
  final double? maxTemp; // MODIFIED: Changed to double?
  final double? minTemp; // MODIFIED: Changed to double?
  final String? rainProb; // Kept nullable as per user feedback
  final DateTime startTime;
  final int timestamp;
  final String weather; // Non-nullable
  final String windDirection; // Non-nullable
  final double? windSpeed; // MODIFIED: Changed to double?

  WeeklyForecastItem({
    required this.comfort,
    required this.endTime,
    required this.humidity,
    required this.maxTemp,
    required this.minTemp,
    this.rainProb, // Kept nullable
    required this.startTime,
    required this.timestamp,
    required this.weather,
    required this.windDirection,
    required this.windSpeed,
  });

  factory WeeklyForecastItem.fromMap(Map<String, dynamic> data) {
    log('WeeklyForecastItem.fromMap - Raw data: $data', name: 'WeatherModelDebug');

    // Logging and safe access for comfort
    if (data['comfort'] == null) {
      log('WARNING: WeeklyForecastItem.fromMap - comfort is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final comfortValue = data['comfort'] as String? ?? ''; 

    final endTimeValue = _parseDateTimeSafely(data['endTime']); // Using helper for endTime

    // Logging and safe access for humidity
    if (data['humidity'] == null) {
      log('WARNING: WeeklyForecastItem.fromMap - humidity is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final humidityValue = data['humidity'] as String? ?? ''; 

    final maxTempValue = (data['maxTemp'] as num?)?.toDouble(); // MODIFIED: Use .toDouble()
    final minTempValue = (data['minTemp'] as num?)?.toDouble(); // MODIFIED: Use .toDouble()
    
    // rainProb remains nullable in model and handled with ?? '0%'
    final rainProbValue = data['rainProb'] as String? ?? '0%';

    final startTimeValue = _parseDateTimeSafely(data['startTime']); // Using helper for startTime

    final timestampValue = (data['timestamp'] as num?)?.toInt() ?? 0;

    // Logging and safe access for weather
    if (data['weather'] == null) {
      log('WARNING: WeeklyForecastItem.fromMap - weather is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final weatherValue = data['weather'] as String? ?? ''; 

    // Logging and safe access for windDirection
    if (data['windDirection'] == null) {
      log('WARNING: WeeklyForecastItem.fromMap - windDirection is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final windDirectionValue = data['windDirection'] as String? ?? ''; 

    // Logging and safe access for windSpeed
    if (data['windSpeed'] == null) {
      log('WARNING: WeeklyForecastItem.fromMap - windSpeed is null in raw data. Using default 0.', name: 'WeatherModelDebug');
    }
    final windSpeedValue = (data['windSpeed'] as num?)?.toDouble() ?? 0.0; // MODIFIED: Use .toDouble() and default 0.0

    log('WeeklyForecastItem.fromMap - Parsed: comfort=$comfortValue, endTime=$endTimeValue, humidity=$humidityValue, maxTemp=$maxTempValue, minTemp=$minTempValue, rainProb=$rainProbValue, startTime=$startTimeValue, timestamp=$timestampValue, weather=$weatherValue, windDirection=$windDirectionValue, windSpeed=$windSpeedValue', name: 'WeatherModelDebug');

    return WeeklyForecastItem(
      comfort: comfortValue,
      endTime: endTimeValue,
      humidity: humidityValue,
      maxTemp: maxTempValue,
      minTemp: minTempValue,
      rainProb: rainProbValue,
      startTime: startTimeValue,
      timestamp: timestampValue,
      weather: weatherValue,
      windDirection: windDirectionValue,
      windSpeed: windSpeedValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comfort': comfort,
      'endTime': endTime.toIso8601String(),
      'humidity': humidity,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      if (rainProb != null) 'rainProb': rainProb,
      'startTime': startTime.toIso8601String(),
      'timestamp': timestamp,
      'weather': weather,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
    };
  }
}

// 代表 weekly 子集合中的單一文件
class WeeklyWeatherForecast {
  final String id;
  final String countyName; // Non-nullable
  final List<WeeklyForecastItem> forecasts;
  final LocationData location; // MODIFIED: Changed to non-nullable
  final DateTime updatedAt;

  WeeklyWeatherForecast({
    required this.id,
    required this.countyName,
    required this.forecasts,
    required this.location, // MODIFIED: Set as required
    required this.updatedAt,
  });

  factory WeeklyWeatherForecast.fromDocument(Map<String, dynamic> data, String id) {
    log('WeeklyWeatherForecast.fromDocument - Raw data for id $id: $data', name: 'WeatherModelDebug');
    List<WeeklyForecastItem> parsedForecasts = [];
    if (data['forecasts'] != null) {
      for (var forecastMap in data['forecasts']) {
        parsedForecasts.add(WeeklyForecastItem.fromMap(forecastMap as Map<String, dynamic>));
      }
    }

    // Logging and safe access for countyName
    if (data['countyName'] == null) {
      log('WARNING: WeeklyWeatherForecast.fromDocument - countyName is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final countyNameValue = data['countyName'] as String? ?? ''; // Safe cast and default
    
    // MODIFIED: Always provide a LocationData instance, even if raw data for 'location' is null
    final locationValue = data['location'] != null 
        ? LocationData.fromMap(data['location'] as Map<String, dynamic>)
        : LocationData(latitude: 0.0, longitude: 0.0, timestamp: 0, townName: '', updatedAt: DateTime.now());

    final updatedAtValue = _parseDateTimeSafely(data['updatedAt']); // Using helper for updatedAt

    log('WeeklyWeatherForecast.fromDocument - Parsed: id=$id, countyName=$countyNameValue, location=$locationValue, updatedAt=$updatedAtValue', name: 'WeatherModelDebug');

    return WeeklyWeatherForecast(
      id: id,
      countyName: countyNameValue,
      forecasts: parsedForecasts,
      location: locationValue, // Will always be non-null now
      updatedAt: updatedAtValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countyName': countyName,
      'forecasts': forecasts.map((f) => f.toMap()).toList(),
      'location': location.toMap(), // No longer nullable access here
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// 代表 weather_forecasts 集合中的每個主要文件 (3小時預報)
class WeatherForecast {
  final String id;
  final String countyName; // Non-nullable
  final List<Forecast> forecasts;
  final LocationData location; // MODIFIED: Changed to non-nullable
  final DateTime updatedAt;
  WeeklyWeatherForecast? weeklyForecast;

  WeatherForecast({
    required this.id,
    required this.countyName,
    required this.forecasts,
    required this.location, // MODIFIED: Set as required
    required this.updatedAt,
    this.weeklyForecast,
  });

  factory WeatherForecast.fromDocument(Map<String, dynamic> data, String id) {
    log('WeatherForecast.fromDocument - Raw data for id $id: $data', name: 'WeatherModelDebug');
    List<Forecast> parsedForecasts = [];
    if (data['forecasts'] != null) {
      for (var forecastMap in data['forecasts']) {
        parsedForecasts.add(Forecast.fromMap(forecastMap as Map<String, dynamic>));
      }
    }

    // Logging and safe access for countyName
    if (data['countyName'] == null) {
      log('WARNING: WeatherForecast.fromDocument - countyName is null in raw data. Using default empty string.', name: 'WeatherModelDebug');
    }
    final countyNameValue = data['countyName'] as String? ?? ''; // Safe cast and default

    // MODIFIED: Always provide a LocationData instance, even if raw data for 'location' is null
    final locationValue = data['location'] != null 
        ? LocationData.fromMap(data['location'] as Map<String, dynamic>)
        : LocationData(latitude: 0.0, longitude: 0.0, timestamp: 0, townName: '', updatedAt: DateTime.now());

    final updatedAtValue = _parseDateTimeSafely(data['updatedAt']); // Using helper for updatedAt

    log('WeatherForecast.fromDocument - Parsed: id=$id, countyName=$countyNameValue, location=$locationValue, updatedAt=$updatedAtValue', name: 'WeatherModelDebug');

    return WeatherForecast(
      id: id,
      countyName: countyNameValue,
      forecasts: parsedForecasts,
      location: locationValue, // Will always be non-null now
      updatedAt: updatedAtValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countyName': countyName,
      'forecasts': forecasts.map((f) => f.toMap()).toList(),
      'location': location.toMap(), // No longer nullable access here
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
