import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../data/models/ui_weather_forecast.dart';
import '../utils/weather_icon_mapper.dart';
import 'weather_card.dart';
import 'package:fl_chart/fl_chart.dart';

const double _hourlyItemWidth = 80.0;

/// A helper function to get the final SVG asset path.
String _getIconAssetPath(String? description, {required bool isNight}) {
  const String basePath = 'assets/icons/';
  const String defaultCode = '4'; // Default to '多雲'

  if (description == null || description.isEmpty) {
    return '$basePath$defaultCode.svg';
  }

  final int? code = descriptionToCodeMap[description];

  if (code == null) {
    return '$basePath$defaultCode.svg';
  }

  if (isNight && dayNightWeatherCodes.contains(code)) {
    return '$basePath$code-1.svg';
  }

  return '$basePath$code.svg';
}

Widget _buildCombinedHourlyItem(
    BuildContext context, 
    HourlyForecast forecast, 
    HourlyForecast? previousForecast,
) {
  final bool isNewDay = previousForecast != null && forecast.time.day != previousForecast.time.day;
  final String formattedTime;
  if (isNewDay) {
    formattedTime = DateFormat('M/d').format(forecast.time);
  } else {
    formattedTime = DateFormat.Hm().format(forecast.time);
  }

  final temperatureText = '${forecast.temperature.round()}°';
  
  final chanceOfRainText = forecast.precipitationChance != null 
      ? '${forecast.precipitationChance}%' 
      : '--';
  
  final bool isNight = forecast.time.hour < 6 || forecast.time.hour >= 18;
  final iconPath = _getIconAssetPath(forecast.iconCode, isNight: isNight);

  const double iconSize = 30.0; 

  Color tempTextColor;
  if (forecast.temperature >= 30) {
    tempTextColor = Colors.red[400]!;
  } else if (forecast.temperature >= 25) {
    tempTextColor = Colors.orange[400]!;
  } else if (forecast.temperature >= 20) {
    tempTextColor = Colors.yellow[700]!;
  } else if (forecast.temperature >= 15) {
    tempTextColor = Colors.green[400]!;
  } else {
    tempTextColor = Colors.blue[400]!;
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        formattedTime,
        style: isNewDay
            ? const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              )
            : TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
      ),
      const SizedBox(height: 8),
      SvgPicture.asset(
        iconPath,
        width: iconSize,
        height: iconSize,
        placeholderBuilder: (BuildContext context) => Icon(Icons.wb_cloudy_outlined, size: iconSize, color: Colors.grey),
      ),
      
      const SizedBox(height: 8),
      
      Text(
        chanceOfRainText,
        style: TextStyle(
          fontSize: 11, 
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      
      const Spacer(), // Use Spacer to create flexible, symmetrical space
      
      Text(
        temperatureText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: tempTextColor,
        ),
      ),
    ],
  );
}

Widget _buildTemperatureChart(
  BuildContext context,
  List<HourlyForecast> chartForecasts,
  double totalChartWidth,
) {
  if (chartForecasts.isEmpty) {
    return const SizedBox.shrink();
  }

  final double dataMinTemp = chartForecasts.map((f) => f.temperature).reduce((a, b) => a < b ? a : b);
  final double dataMaxTemp = chartForecasts.map((f) => f.temperature).reduce((a, b) => a > b ? a : b);

  const double minChartYSpan = 6.0; 
  const double chartVerticalPadding = 2.0;

  double effectiveMinTemp = dataMinTemp;
  double effectiveMaxTemp = dataMaxTemp;

  if ((effectiveMaxTemp - effectiveMinTemp) < minChartYSpan) {
    final double centerTemp = (effectiveMinTemp + effectiveMaxTemp) / 2;
    effectiveMinTemp = centerTemp - (minChartYSpan / 2);
    effectiveMaxTemp = centerTemp + (minChartYSpan / 2);
  }

  const double itemWidth = _hourlyItemWidth;
  
  final spots = chartForecasts.asMap().entries.map((entry) {
    final index = entry.key;
    final forecast = entry.value;
    final double xPosition = (index * itemWidth) + (itemWidth / 2);
    return FlSpot(
      xPosition,
      forecast.temperature.toDouble(),
    );
  }).toList();

  return LineChart(
    LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.grey[400]!,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.grey[400]!, 
                strokeColor: Colors.white,
                strokeWidth: 1,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      minY: effectiveMinTemp - chartVerticalPadding,
      maxY: effectiveMaxTemp + chartVerticalPadding,
      minX: 0,
      maxX: totalChartWidth,
    ),
  );
}

class HourlyForecastCard extends StatelessWidget {
  final List<HourlyForecast> hourlyForecasts;

  const HourlyForecastCard({super.key, required this.hourlyForecasts});

  @override
  Widget build(BuildContext context) {
    const double totalHeight = 180; // Provide ample and predictable total height
    
    final double totalScrollableWidth = hourlyForecasts.length * _hourlyItemWidth;

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '3小時天氣預報',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          if (hourlyForecasts.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: totalHeight,
                width: totalScrollableWidth,
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: hourlyForecasts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final forecast = entry.value;
                        final HourlyForecast? previousForecast = (index > 0) ? hourlyForecasts[index - 1] : null;
                        
                        return SizedBox(
                          width: _hourlyItemWidth,
                          child: _buildCombinedHourlyItem(context, forecast, previousForecast)
                        );
                      }).toList(),
                    ),
                    
                    Positioned(
                      // Position the chart relative to the top and bottom of the Stack
                      top: 85,  // Estimated height of top group + padding
                      bottom: 25, // Estimated height of bottom group + padding
                      left: 0,
                      right: 0,
                      child: _buildTemperatureChart(
                        context,
                        hourlyForecasts,
                        totalScrollableWidth,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  '暫無預報數據',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
