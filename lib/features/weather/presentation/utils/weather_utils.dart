import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart'; // Using WeatherIcons now

// Map weather icon code to WeatherIcons data, including composite icons
IconData getWeatherIcon(String iconCode) {
  switch (iconCode) {
    // --- Day Icons ---
    case 'f00d': return WeatherIcons.day_sunny;
    case 'f002': return WeatherIcons.day_cloudy;
    case 'f013': return WeatherIcons.cloudy; // General cloudy, more than partly
    case 'f00e': return WeatherIcons.day_rain;
    case 'f008': return WeatherIcons.day_rain_mix; // Sun with rain
    case 'f009': return WeatherIcons.day_showers;
    case 'f010': return WeatherIcons.day_thunderstorm;
    case 'f00a': return WeatherIcons.day_snow;
    case 'f06b': return WeatherIcons.day_snow_wind;
    case 'f06d': return WeatherIcons.day_snow_thunderstorm;

    // --- Night Icons ---
    case 'f02e': return WeatherIcons.night_clear;
    case 'f086': return WeatherIcons.night_alt_cloudy;
    case 'f036': return WeatherIcons.night_rain;
    case 'f028': return WeatherIcons.night_alt_rain_mix;
    case 'f029': return WeatherIcons.night_alt_showers;
    case 'f01d': return WeatherIcons.night_thunderstorm;
    case 'f02a': return WeatherIcons.night_snow;
    case 'f06c': return WeatherIcons.night_alt_snow_wind;
    case 'f06e': return WeatherIcons.night_alt_snow_thunderstorm;

    // --- Neutral Icons ---
    case 'f003': return WeatherIcons.fog;
    case 'f04a': return WeatherIcons.fog; // Night fog is the same icon
    case 'f011': return WeatherIcons.thunderstorm; // General thunderstorm
    case 'f064': return WeatherIcons.hail; // Hail
    case 'f076': return WeatherIcons.snowflake_cold; // Blizzard/Extreme Cold

    default: return WeatherIcons.na; // Default to 'not available'
  }
}

// Map quality level to color (example for AQI/UV)
Color getQualityColor(String level) {
    switch (level.toLowerCase()) {
      case '良好': return Colors.green;
      case '中等': return Colors.orange;
      case '差': return Colors.red;
      default: return Colors.grey;
    }
}

// Get a representative color for a weather icon (can be expanded)
Color getWeatherIconColor(String iconCode) {
  // Simple color scheme, can be made more detailed
  if (iconCode.contains('f00d') || iconCode.contains('f02e')) return Colors.orangeAccent; // Sun/Clear
  if (iconCode.contains('rain') || iconCode.contains('showers') || iconCode.contains('f00e') || iconCode.contains('f036')) return Colors.blue;
  if (iconCode.contains('thunderstorm') || iconCode.contains('f010') || iconCode.contains('f01d')) return Colors.deepPurple;
  if (iconCode.contains('snow') || iconCode.contains('f00a') || iconCode.contains('f02a')) return Colors.lightBlueAccent;
  if (iconCode.contains('fog') || iconCode.contains('f003') || iconCode.contains('f04a')) return Colors.grey;
  
  return Colors.blueGrey; // Default for cloudy/mixed
}
