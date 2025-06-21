
import 'package:flutter/material.dart'; // For Color and TimeOfDay

// Represents the main weather data for a location
class WeatherInfo {
  final String locationName;
  final DateTime lastUpdated;
  final String condition;
  final String iconCode;
  final double temperature;
  final double feelsLike;
  final double tempHigh;
  final double tempLow;
  final double tempYesterdayHigh; // As per screenshot
  final double tempYesterdayLow;  // As per screenshot
  final double windSpeed; // km/h
  final int humidity; // %
  final int precipitationChance; // %
  final int aqi;
  final String aqiLevel; // e.g., '良好'
  final int uvIndex;
  final String uvLevel; // e.g., '中等'
  final String clothingAdvice; // e.g., '舒適'
  final int clothingIndexValue; // Numerical value for clothing advice (e.g., 1-5)
  final String umbrellaAdvice; // e.g., '良好' (Corresponds to '曬衣指數')
  final int umbrellaIndexValue; // Numerical value for umbrella/drying index
  final String activityAdvice; // e.g., '適宜' (Corresponds to '運動指數')
  final int activityIndexValue; // Numerical value for activity index
  final String aiSummary;
  final TimeOfDay sunrise;
  final TimeOfDay sunset;
  final List<HourlyForecast> hourlyForecasts;
  final List<DailyForecast> dailyForecasts;

  WeatherInfo({
    required this.locationName,
    required this.lastUpdated,
    required this.condition,
    required this.iconCode,
    required this.temperature,
    required this.feelsLike,
    required this.tempHigh,
    required this.tempLow,
    required this.tempYesterdayHigh,
    required this.tempYesterdayLow,
    required this.windSpeed,
    required this.humidity,
    required this.precipitationChance,
    required this.aqi,
    required this.aqiLevel,
    required this.uvIndex,
    required this.uvLevel,
    required this.clothingAdvice,
    required this.clothingIndexValue, // New field
    required this.umbrellaAdvice,
    required this.umbrellaIndexValue, // New field
    required this.activityAdvice,
    required this.activityIndexValue, // New field
    required this.aiSummary,
    required this.sunrise,
    required this.sunset,
    required this.hourlyForecasts,
    required this.dailyForecasts,
  });
}

// Represents a single hour's forecast
class HourlyForecast {
  final DateTime time;
  final String iconCode;
  final double temperature;
  final int precipitationChance; // %

  HourlyForecast({
    required this.time,
    required this.iconCode,
    required this.temperature,
    required this.precipitationChance,
  });
}

// Represents a single day's forecast
class DailyForecast {
  final DateTime date;
  final String dayName; // e.g., '今天', '週二'
  final String dayIconCode;
  final int dayPrecipitationChance; // %
  final double dayTempHigh;
  final double dayTempLow; // Added day low temperature
  final String nightIconCode;
  final int nightPrecipitationChance; // %
  final double nightTempHigh; // Added night high temperature
  final double nightTempLow;

  DailyForecast({
    required this.date,
    required this.dayName,
    required this.dayIconCode,
    required this.dayPrecipitationChance,
    required this.dayTempHigh,
    required this.dayTempLow, // Added to constructor
    required this.nightIconCode,
    required this.nightPrecipitationChance,
    required this.nightTempHigh, // Added to constructor
    required this.nightTempLow,
  });
}


// Represents a weather alert
class WeatherAlert {
  final String title;
  final String description;
  final DateTime issuedTime;
  final String authorName;

  WeatherAlert({
    required this.title,
    required this.description,
    required this.issuedTime,
    required this.authorName,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      title: json['title'] ?? 'No Title',
      description: json['summary']['#text'] ?? 'No Description',
      issuedTime: DateTime.parse(json['updated']), // Assuming 'updated' is always present and valid
      authorName: json['author']['name'] ?? 'Unknown Author',
    );
  }
}
