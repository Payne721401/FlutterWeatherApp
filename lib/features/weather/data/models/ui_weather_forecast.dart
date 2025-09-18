/// Defines the data models specifically tailored for the UI layer.
/// These models are clean, type-safe, and contain only the data
/// necessary for presentation, after being transformed from raw data models
/// in the Repository layer.

class HourlyForecast {
  /// The specific time for this forecast.
  final DateTime time;

  /// A code representing the weather icon to be displayed (e.g., '01d').
  final String iconCode;

  /// The temperature for this hour.
  final double temperature;

  /// The apparent temperature (feels like) for this hour.
  final double? apparentTemperature;

  /// The chance of precipitation as a percentage (e.g., 10 for 10%).
  /// This is nullable to handle cases where the source data is invalid (e.g., -99).
  final int? precipitationChance;

  HourlyForecast({
    required this.time,
    required this.iconCode,
    required this.temperature,
    this.apparentTemperature,
    this.precipitationChance,
  });
}

class DailyForecast {
  /// The date of the forecast.
  final DateTime date;

  /// The display name for the day (e.g., '今天', '週二').
  final String dayName;

  /// A code representing the weather icon for the day.
  final String dayIconCode;

  /// A code representing the weather icon for the night.
  final String? nightIconCode;

  /// The highest temperature expected for the day.
  final double dayTempHigh;

  /// The lowest temperature expected for the day.
  final double dayTempLow;

  /// The highest apparent temperature (feels like) expected for the day.
  final double? dayMaxApparentTemperature;

  /// The lowest apparent temperature (feels like) expected for the day.
  final double? dayMinApparentTemperature;

  /// The chance of precipitation during the day as a percentage.
  /// This is nullable to handle cases where the source data is invalid or null.
  final int? dayPrecipitationChance;

  /// The average humidity for the day as a percentage.
  final int? humidity;

  DailyForecast({
    required this.date,
    required this.dayName,
    required this.dayIconCode,
    this.nightIconCode,
    required this.dayTempHigh,
    required this.dayTempLow,
    this.dayMaxApparentTemperature,
    this.dayMinApparentTemperature,
    this.dayPrecipitationChance,
    this.humidity,
  });
}
