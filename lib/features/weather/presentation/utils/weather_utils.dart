import 'package:flutter/material.dart';

// Map weather icon code to Material icon data
IconData getWeatherIcon(String iconCode) {
  // Remapped based on general conventions and provided screenshots
    switch (iconCode) {
      case '01d': return Icons.wb_sunny; // Sunny day
      case '01n': return Icons.nights_stay; // Clear night
      case '02d': return Icons.wb_cloudy_outlined; // Partly cloudy day
      case '02n': return Icons.wb_cloudy_outlined; // Partly cloudy night
      case '03d':
      case '03n': return Icons.cloud_outlined; // Scattered clouds
      case '04d':
      case '04n': return Icons.cloud; // Broken clouds / Overcast
      case '09d':
      case '09n': return Icons.water_drop; // Shower rain
      case '10d': return Icons.grain; // Rain (using grain for visual separation)
      case '10n': return Icons.grain;
      case '11d':
      case '11n': return Icons.flash_on; // Thunderstorm
      case '13d':
      case '13n': return Icons.ac_unit; // Snow
      case '50d':
      case '50n': return Icons.foggy; // Mist
      default: return Icons.cloud_off;
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

// Get a representative color for a weather icon
Color getWeatherIconColor(String iconCode) {
  switch (iconCode) {
    case '01d': return Colors.orangeAccent; // Sunny day
    case '01n': return Colors.indigo; // Clear night
    case '02d':
    case '02n':
    case '03d':
    case '03n':
    case '04d':
    case '04n': return Colors.blueGrey; // Cloudy
    case '09d':
    case '09n':
    case '10d':
    case '10n': return Colors.blue; // Rainy
    case '11d':
    case '11n': return Colors.deepPurple; // Thunderstorm
    case '13d':
    case '13n': return Colors.lightBlueAccent; // Snow
    case '50d':
    case '50n': return Colors.grey; // Mist
    default: return Colors.grey;
  }
}
