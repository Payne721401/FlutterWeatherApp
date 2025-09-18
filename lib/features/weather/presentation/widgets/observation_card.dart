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

class ObservationCard extends StatelessWidget {
  final String? stationName;
  final double? windSpeed;
  final double? windDirection;
  final int? humidity;
  final double? precipitation;
  final int? uvIndex;
  final String? uvLevel;
  final int? aqi;
  final String? aqiLevel;
  final TimeOfDay? sunrise;
  final TimeOfDay? sunset;

  const ObservationCard({
    super.key,
    this.stationName,
    this.windSpeed,
    this.windDirection,
    this.humidity,
    this.precipitation,
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
                          color: valueColor?.withAlpha((255 * 0.2).round()),
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

  String _getWindDirectionText(double? angle) {
    if (angle == null) return '';
    const directions = ['北', '北北東', '東北', '東北東', '東', '東南東', '東南', '南南東', '南', '南南西', '西南', '西南西', '西', '西北西', '西北', '北北西'];
    return directions[((angle / 22.5) + 0.5).floor() % 16];
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
    final windDirectionText = _getWindDirectionText(windDirection);
    final windSpeedText = windSpeed != null ? '${windSpeed!.round()}級 $windDirectionText'.trim() : '無資料';
    
    final humidityText = humidity != null ? '$humidity%' : '無資料';
    final precipitationText = precipitation != null ? '${precipitation!.toStringAsFixed(1)} mm' : '無資料';

    final uvIndexValue = uvIndex?.toDouble();
    final uvIndexText = uvIndexValue != null ? '${uvIndexValue.round()}' : '無資料';
    final uvIndexColor = uvIndexValue != null ? _getUvIndexColor(uvIndexValue) : null;
    final uvIndexLevelText = uvIndexValue != null ? uvLevel ?? _getUvIndexLevelText(uvIndexValue) : null;

    final aqiValue = aqi?.toDouble();
    final airQualityIndexText = aqiValue != null ? '${aqiValue.round()}' : '無資料';
    final airQualityColor = aqiValue != null ? _getAirQualityColor(aqiValue) : null;
    final airQualityLevelText = aqiValue != null ? aqiLevel ?? _getAirQualityLevelText(aqiValue) : null;

    final sunriseTime = sunrise != null ? DateFormat.Hm().format(_timeOfDayToDateTime(sunrise!)) : '--:--';
    final sunsetTime = sunset != null ? DateFormat.Hm().format(_timeOfDayToDateTime(sunset!)) : '--:--';
    final sunriseSunsetText = sunrise != null && sunset != null ? '$sunriseTime / $sunsetTime' : '無資料';

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
      sunriseSunsetText,
    );

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('天氣觀測站${stationName != null ? ' ($stationName)' : ''}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                    _buildWeatherDetailItem(Icons.umbrella, '累積雨量', precipitationText),
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
          if (sunrise != null && sunset != null)
          SizedBox(
            height: 50,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textStyle = TextStyle(fontSize: 12, color: Colors.grey[600]);

                final sunrisePainter = TextPainter(
                  text: TextSpan(text: sunriseTime, style: textStyle),
                  textDirection: Directionality.of(context),
                )..layout();

                final sunsetPainter = TextPainter(
                  text: TextSpan(text: sunsetTime, style: textStyle),
                  textDirection: Directionality.of(context),
                )..layout();

                final double paddingLeft = sunrisePainter.width / 2;
                final double paddingRight = sunsetPainter.width / 2;

                return Stack(
                   clipBehavior: Clip.none,
                  children: [
                     Positioned.fill(
                       child: Padding(
                         padding: EdgeInsets.only(left: paddingLeft, right: paddingRight),
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
                     ),
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Text(sunriseTime, style: textStyle),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text(sunsetTime, style: textStyle),
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
