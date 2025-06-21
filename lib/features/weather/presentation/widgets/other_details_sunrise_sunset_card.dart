import 'package:flutter/material.dart';
import '../../data/models/weather_data.dart';
import 'package:intl/intl.dart'; // For time formatting
import 'weather_card.dart'; // Import WeatherCard
// import 'dart:math'; // Import for sin function (for curved line)

// Custom painter for the sunrise/sunset timeline curve
class SunriseSunsetTimelinePainter extends CustomPainter {
  final double currentPositionPercentage;
  final Color lineColor;
  final Color dotColor;
  final double dotSize;
  final double curveDepth; // Changed from curveHeight to curveDepth for clarity

  SunriseSunsetTimelinePainter({
    required this.currentPositionPercentage,
    required this.lineColor,
    required this.dotColor,
    required this.dotSize,
    this.curveDepth = 35.0, // Increased curve depth
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Define start and end points of the line
    final startPoint = Offset(0, size.height / 2);
    final endPoint = Offset(size.width, size.height / 2);

    // Define a control point for a gentle upward curve
    // The Y-coordinate is size.height / 2 - curveDepth to make it go upwards
    final controlPoint = Offset(size.width / 2, size.height / 2 - curveDepth); // MODIFIED

    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    canvas.drawPath(path, paint);

    // Draw the current time dot along the curve (approximated)
    if (currentPositionPercentage >= 0.0 && currentPositionPercentage <= 1.0) {
      final t = currentPositionPercentage;

      // Calculate dot position using quadratic Bezier formula
      final dotX = (1 - t) * (1 - t) * startPoint.dx +
                   2 * (1 - t) * t * controlPoint.dx +
                   t * t * endPoint.dx;
      final dotY = (1 - t) * (1 - t) * startPoint.dy +
                   2 * (1 - t) * t * controlPoint.dy +
                   t * t * endPoint.dy;

      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(Offset(dotX, dotY), dotSize / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint if the current position percentage or curve depth changes
    return oldDelegate is SunriseSunsetTimelinePainter &&
           (oldDelegate.currentPositionPercentage != currentPositionPercentage ||
            oldDelegate.curveDepth != curveDepth);
  }
}


class OtherDetailsSunriseSunsetCard extends StatelessWidget {
  final WeatherInfo data;

  const OtherDetailsSunriseSunsetCard({super.key, required this.data});

  // Helper function to build weather detail item (icon, title, value)
  Widget _buildWeatherDetailItem(IconData icon, String title, String value, {Color? valueColor, String? levelText}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically to center
        children: [
          Icon(icon, size: 28, color: Colors.grey[700]), // Increased icon size
          const SizedBox(width: 12), // Spacing between icon and text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Vertically center the column content
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])), // Title
                const SizedBox(height: 2), // Spacing between title and value
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)), // Value
                     if (levelText != null) ...[ // Display level text if available
                      const SizedBox(width: 6), // Spacing between value and level text
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

  // Helper function to determine UV Index color
  Color _getUvIndexColor(double uvIndex) {
    if (uvIndex < 3) return Colors.green;
    if (uvIndex < 6) return Colors.orange;
    if (uvIndex < 8) return Colors.red;
    if (uvIndex < 11) return Colors.purple;
    return Colors.deepPurple;
  }

  // Helper function to get UV Index level text
  String _getUvIndexLevelText(double uvIndex) {
     if (uvIndex < 3) return '低量';
     if (uvIndex < 6) return '中量';
     if (uvIndex < 8) return '高量';
     if (uvIndex < 11) return '過量';
     return '危險';
  }

   // Helper function to determine Air Quality Index color
  Color _getAirQualityColor(double aqi) {
    if (aqi < 51) return Colors.green; // Good
    if (aqi < 101) return Colors.orange; // Moderate
    if (aqi < 151) return Colors.red; // Unhealthy for Sensitive Groups
    if (aqi < 201) return Colors.purple; // Unhealthy
    if (aqi < 301) return Colors.deepPurple; // Very Unhealthy
    return Colors.brown; // Hazardous
  }

  // Helper function to get Air Quality Index level text
  String _getAirQualityLevelText(double aqi) {
    if (aqi < 51) return '良好';
    if (aqi < 101) return '普通';
    if (aqi < 151) return '對敏感族群不健康';
    if (aqi < 201) return '對所有族群不健康';
    if (aqi < 301) return '非常不健康';
    return '危害';
  }

  // Helper to convert TimeOfDay to DateTime for formatting
  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    // Accessing fields directly from data (non-nullable as per model definition)
    // Safely display wind speed
    final windSpeedText = '${data.windSpeed.round()} km/h'; // Rounded wind speed
    // Safely display humidity
    final humidityText = '${data.humidity}%';
    // Safely display precipitation chance
    final precipitationChanceText = '${data.precipitationChance}%';

    // Safely display UV Index
    final uvIndex = data.uvIndex.toDouble();
    final uvIndexText = '${uvIndex.round()}';
    final uvIndexColor = _getUvIndexColor(uvIndex);
    final uvIndexLevelText = _getUvIndexLevelText(uvIndex);

    // Safely display Air Quality Index
    final aqi = data.aqi.toDouble();
    final airQualityIndexText = '${aqi.round()}';
    final airQualityColor = _getAirQualityColor(aqi);
    final airQualityLevelText = _getAirQualityLevelText(aqi);

    // Safely display sunrise and sunset times
    final sunriseTime = DateFormat.Hm().format(_timeOfDayToDateTime(data.sunrise));
    final sunsetTime = DateFormat.Hm().format(_timeOfDayToDateTime(data.sunset));

    // Calculate current time percentage between sunrise and sunset for the timeline dot
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Get today's date
    // Combine today's date with TimeOfDay for full DateTime objects
    final sunriseDateTime = DateTime(today.year, today.month, today.day, data.sunrise.hour, data.sunrise.minute);
    final sunsetDateTime = DateTime(today.year, today.month, today.day, data.sunset.hour, data.sunset.minute);

    // Handle cases where sunrise might be technically on the next day (e.g., late night)
    final effectiveSunrise = sunriseDateTime.isAfter(sunsetDateTime) ? sunriseDateTime.subtract(const Duration(days: 0)) : sunriseDateTime; // No change if sunrise is earlier
    final effectiveSunset = sunsetDateTime.isBefore(effectiveSunrise) ? sunsetDateTime.add(const Duration(days: 1)) : sunsetDateTime; // Add a day to sunset if it's before sunrise

    final totalDaylightDuration = effectiveSunset.difference(effectiveSunrise);
    final elapsedDuration = now.difference(effectiveSunrise);

    double currentPositionPercentage = 0.0;
    if (totalDaylightDuration.inMinutes > 0 && elapsedDuration.inMinutes >= 0) {
       currentPositionPercentage = (elapsedDuration.inMinutes / totalDaylightDuration.inMinutes).clamp(0.0, 1.0);
    }

    // Create the Sunrise/Sunset detail item content
    final sunriseSunsetDetailItem = _buildWeatherDetailItem(
      Icons.wb_sunny_outlined, // Placeholder icon for sunrise/sunset
      '日出/日落',
      '$sunriseTime / $sunsetTime',
    );

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('天氣觀測站', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), // Changed title
          const SizedBox(height: 16), // Increased spacing after title

          // Other details in two columns
          IntrinsicHeight( // Ensure equal height for rows
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align items at the start of the row
                  children: [
                    _buildWeatherDetailItem(Icons.wind_power, '風速', windSpeedText),
                    const SizedBox(width: 16), // Spacing between items
                    _buildWeatherDetailItem(Icons.water_drop, '濕度', humidityText),
                  ],
                ),
                const SizedBox(height: 12), // Spacing between detail rows
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align items at the start of the row
                  children: [
                    _buildWeatherDetailItem(Icons.umbrella, '降雨機率', precipitationChanceText),
                    const SizedBox(width: 16), // Spacing between items
                    _buildWeatherDetailItem(
                      Icons.sunny,
                      '紫外線指數',
                      uvIndexText,
                      valueColor: uvIndexColor,
                      levelText: uvIndexLevelText,
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Spacing between detail rows
                 Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align items at the start of the row
                  children: [
                    _buildWeatherDetailItem(
                      Icons.air,
                      '空氣品質',
                      airQualityIndexText,
                      valueColor: airQualityColor,
                      levelText: airQualityLevelText,
                    ),
                    // Add the Sunrise/Sunset detail item here
                    const SizedBox(width: 16), // Spacing between items
                    sunriseSunsetDetailItem,
                  ],
                ),
              ],
            ),
          ),

          // Sunrise/Sunset timeline visualization (at the bottom)
          const SizedBox(height: 24), // Increased spacing before timeline
          SizedBox(
            height: 50, // Height to accommodate the curve and labels
            child: LayoutBuilder( // Use LayoutBuilder to get the available width
              builder: (context, constraints) {
                // final timelineWidth = constraints.maxWidth; // THIS LINE IS NOT USED AND CAN BE REMOVED
                 // Calculate dot position based on percentage and available width
                 // Subtract half the dot width to attempt to center it (simplification)
                // final dotPosition = currentPositionPercentage * timelineWidth - (12/2); // THIS LINE IS NOT USED AND CAN BE REMOVED

                return Stack(
                   clipBehavior: Clip.none, // Allow children to overflow
                  children: [
                     // Curved Timeline Line and Dot (drawn by CustomPainter)
                     Positioned.fill(
                       child: CustomPaint(
                         painter: SunriseSunsetTimelinePainter(
                           currentPositionPercentage: currentPositionPercentage,
                           lineColor: Colors.amber[700]!, // Use amber color
                           dotColor: Colors.amber[700]!, // Use amber color for dot
                           dotSize: 12.0, // Dot size
                           curveDepth: 35.0, // Control the curve depth here
                         ),
                       ),
                     ),

                    // Sunrise and Sunset time labels (positioned below the timeline)
                    Positioned(
                      left: 0,
                      bottom: 0, // Position at the bottom
                      child: Text(sunriseTime, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0, // Position at the bottom
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