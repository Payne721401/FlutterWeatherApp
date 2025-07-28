import 'package:myapp/features/radar/data/models/rainfall_data.dart';

/// A utility class for calculating rainfall levels based on geographic coordinates.
class RainfallCalculator {
  /// Gets the rainfall level for the given latitude and longitude.
  ///
  /// This is a static method, so it can be called without creating an instance of the class,
  /// making it convenient for use in various parts of the application.
  /// [data]: Cached rainfall data from the RainfallService.
  /// [userLat]: The user's current latitude.
  /// [userLon]: The user's current longitude.
  static RainfallLevel getLevelAt({
    required RainfallData data,
    required double userLat,
    required double userLon,
  }) {
    try {
      final metadata = data.metadata;
      final double startLon = (metadata['start_lon'] as num).toDouble();
      final double startLat = (metadata['start_lat'] as num).toDouble();
      final double resLon = (metadata['res_lon'] as num).toDouble();
      final double resLat = (metadata['res_lat'] as num).toDouble();
      final int dimX = (metadata['dim_x'] as num).toInt();
      final int dimY = (metadata['dim_y'] as num).toInt();

      // --- Core Calculation Logic ---
      int x = ((userLon - startLon) / resLon).floor();
      int y = ((userLat - startLat) / resLat).floor();

      if (x < 0 || x >= dimX || y < 0 || y >= dimY) {
        return RainfallLevel.noRain;
      }

      int index = y * dimX + x;

      if (index < 0 || index >= data.rainfallGrid.length) {
        return RainfallLevel.unknown;
      }
      double rainfall = data.rainfallGrid[index];

      // --- Rainfall Classification ---
      if (rainfall <= 0) {
        return RainfallLevel.noRain;
      } else if (rainfall > 0 && rainfall <= 2.5) {
        return RainfallLevel.lightRain;
      } else if (rainfall > 2.5 && rainfall < 10) {
        return RainfallLevel.moderateRain;
      } else if (rainfall >= 10 && rainfall < 40) {
        return RainfallLevel.heavyRain;
      } else {
        return RainfallLevel.torrentialRain;
      }
    } catch (e) {
      print('Error calculating rainfall level: $e');
      return RainfallLevel.unknown;
    }
  }

  /// Generates a user-friendly forecast message based on the rainfall level.
  static String getForecastMessageFromLevel(RainfallLevel level, String? administrativeDivision) {
    final district = administrativeDivision ?? '目前位置';
    switch (level) {
      case RainfallLevel.noRain:
        return '$district：未來1小時內無降雨';
      case RainfallLevel.lightRain:
        return '$district：未來1小時內有小雨';
      case RainfallLevel.moderateRain:
        return '$district：未來1小時內有中雨';
      case RainfallLevel.heavyRain:
        return '$district：未來1小時內有大雨';
      case RainfallLevel.torrentialRain:
        return '$district：未來1小時內有暴雨';
      case RainfallLevel.unknown:
      default:
        return '降雨預報資料分析中...';
    }
  }
}
