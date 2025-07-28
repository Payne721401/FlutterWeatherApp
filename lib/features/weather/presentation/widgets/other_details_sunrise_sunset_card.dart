import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For time formatting
import 'weather_card.dart'; // Import WeatherCard

// Custom painter for the sunrise/sunset timeline curve
class SunriseSunsetTimelinePainter extends CustomPainter {
  final double currentPositionPercentage;
  final Color lineColor;
  final Color dotColor;
  final double dotSize;
  final double curveDepth;

  SunriseSunsetTimelinePainter({
    required this.currentPositionPercentage,
    required this.lineColor,
    required this.dotColor,
    required this.dotSize,
    this.curveDepth = 35.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final startPoint = Offset(0, size.height / 2);
    final endPoint = Offset(size.width, size.height / 2);
    final controlPoint = Offset(size.width / 2, size.height / 2 - curveDepth);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    canvas.drawPath(path, paint);

    if (currentPositionPercentage >= 0.0 && currentPositionPercentage <= 1.0) {
      final t = currentPositionPercentage;
      final dotX = (1 - t) * (1 - t) * startPoint.dx + 2 * (1 - t) * t * controlPoint.dx + t * t * endPoint.dx;
      final dotY = (1 - t) * (1 - t) * startPoint.dy + 2 * (1 - t) * t * controlPoint.dy + t * t * endPoint.dy;

      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(Offset(dotX, dotY), dotSize / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is SunriseSunsetTimelinePainter &&
           (oldDelegate.currentPositionPercentage != currentPositionPercentage ||
            oldDelegate.curveDepth != curveDepth);
  }
}

class OtherDetailsSunriseSunsetCard extends StatelessWidget {
  // MODIFIED: Use independent, nullable properties instead of the old WeatherInfo model
  final double? windSpeed;
  final int? humidity;
  final int? precipitationChance;
  final int? uvIndex;
  final String? uvLevel;
  final int? aqi;
  final String? aqiLevel;
  final TimeOfDay? sunrise;
  final TimeOfDay? sunset;

  const OtherDetailsSunriseSunsetCard({
    super.key, 
    this.windSpeed,
    this.humidity,
    this.precipitationChance,
    this.uvIndex,
    this.uvLevel,
    this.aqi,
    this.aqiLevel,
    this.sunrise,
    this.sunset,
  });

  Widget _buildWeatherDetailItem(IconData icon, String title, String value, {Color? valueColor, String? levelText}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
                     if (levelText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: valueColor?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          levelText,
                          style: TextStyle(fontSize: 12, color: valueColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUvIndexColor(double uvIndex) {
    if (uvIndex < 3) return Colors.green;
    if (uvIndex < 6) return Colors.orange;
    if (uvIndex < 8) return Colors.red;
    if (uvIndex < 11) return Colors.purple;
    return Colors.deepPurple;
  }

  String _getUvIndexLevelText(double uvIndex) {
     if (uvIndex < 3) return '低量';
     if (uvIndex < 6) return '中量';
     if (uvIndex < 8) return '高量';
     if (uvIndex < 11) return '過量';
     return '危險';
  }

  Color _getAirQualityColor(double aqi) {
    if (aqi < 51) return Colors.green;
    if (aqi < 101) return Colors.orange;
    if (aqi < 151) return Colors.red;
    if (aqi < 201) return Colors.purple;
    if (aqi < 301) return Colors.deepPurple;
    return Colors.brown;
  }

  String _getAirQualityLevelText(double aqi) {
    if (aqi < 51) return '良好';
    if (aqi < 101) return '普通';
    if (aqi < 151) return '對敏感族群不健康';
    if (aqi < 201) return '對所有族群不健康';
    if (aqi < 301) return '非常不健康';
    return '危害';
  }

  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    // MODIFIED: Use passed-in properties with null-safety
    final windSpeedText = '${(windSpeed ?? 0).round()}級';
    final humidityText = '${humidity ?? 0}%';
    final precipitationChanceText = '${precipitationChance ?? 0}%';

    // Safely display UV Index by providing a default value
    final uvIndexValue = (uvIndex ?? 0).toDouble();
    final uvIndexText = '${uvIndexValue.round()}';
    final uvIndexColor = _getUvIndexColor(uvIndexValue);
    final uvIndexLevelText = uvLevel ?? _getUvIndexLevelText(uvIndexValue);

    // Safely display Air Quality Index by providing a default value
    final aqiValue = (aqi ?? 0).toDouble();
    final airQualityIndexText = '${aqiValue.round()}';
    final airQualityColor = _getAirQualityColor(aqiValue);
    final airQualityLevelText = aqiLevel ?? _getAirQualityLevelText(aqiValue);

    // MODIFIED: Handle nullable sunrise/sunset times
    final sunriseTime = sunrise != null ? DateFormat.Hm().format(_timeOfDayToDateTime(sunrise!)) : '--:--';
    final sunsetTime = sunset != null ? DateFormat.Hm().format(_timeOfDayToDateTime(sunset!)) : '--:--';

    double currentPositionPercentage = 0.0;
    if (sunrise != null && sunset != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sunriseDateTime = DateTime(today.year, today.month, today.day, sunrise!.hour, sunrise!.minute);
      final sunsetDateTime = DateTime(today.year, today.month, today.day, sunset!.hour, sunset!.minute);
      
      final effectiveSunrise = sunriseDateTime.isAfter(sunsetDateTime) ? sunriseDateTime.subtract(const Duration(days: 0)) : sunriseDateTime;
      final effectiveSunset = sunsetDateTime.isBefore(effectiveSunrise) ? sunsetDateTime.add(const Duration(days: 1)) : sunsetDateTime;

      final totalDaylightDuration = effectiveSunset.difference(effectiveSunrise);
      final elapsedDuration = now.difference(effectiveSunrise);
      
      if (totalDaylightDuration.inMinutes > 0 && elapsedDuration.inMinutes >= 0) {
         currentPositionPercentage = (elapsedDuration.inMinutes / totalDaylightDuration.inMinutes).clamp(0.0, 1.0);
      }
    }

    final sunriseSunsetDetailItem = _buildWeatherDetailItem(
      Icons.wb_sunny_outlined,
      '日出/日落',
      '$sunriseTime / $sunsetTime',
    );

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('天氣觀測站', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherDetailItem(Icons.wind_power, '風速', windSpeedText),
                    const SizedBox(width: 16),
                    _buildWeatherDetailItem(Icons.water_drop, '濕度', humidityText),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherDetailItem(Icons.umbrella, '降雨機率', precipitationChanceText),
                    const SizedBox(width: 16),
                    _buildWeatherDetailItem(
                      Icons.sunny,
                      '紫外線指數',
                      uvIndexText,
                      valueColor: uvIndexColor,
                      levelText: uvIndexLevelText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                 Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherDetailItem(
                      Icons.air,
                      '空氣品質',
                      airQualityIndexText,
                      valueColor: airQualityColor,
                      levelText: airQualityLevelText,
                    ),
                    const SizedBox(width: 16),
                    sunriseSunsetDetailItem,
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                   clipBehavior: Clip.none,
                  children: [
                     Positioned.fill(
                       child: CustomPaint(
                         painter: SunriseSunsetTimelinePainter(
                           currentPositionPercentage: currentPositionPercentage,
                           lineColor: Colors.amber[700]!,
                           dotColor: Colors.amber[700]!,
                           dotSize: 12.0,
                           curveDepth: 35.0,
                         ),
                       ),
                     ),
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Text(sunriseTime, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text(sunsetTime, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
