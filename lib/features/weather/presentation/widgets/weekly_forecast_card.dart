import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../data/models/ui_weather_forecast.dart';
import '../utils/weather_icon_mapper.dart'; 
import 'weather_card.dart';
import 'package:fl_chart/fl_chart.dart';

const double _dailyItemWidth = 80.0;

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


class WeeklyForecastCard extends StatelessWidget {
  final List<DailyForecast> dailyForecasts;

  const WeeklyForecastCard({super.key, required this.dailyForecasts});

  @override
  Widget build(BuildContext context) {
    final double totalScrollableWidth = dailyForecasts.length * _dailyItemWidth;

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("一週天氣預報", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          if (dailyForecasts.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 280,
                width: totalScrollableWidth,
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: dailyForecasts.map((forecast) {
                        return _DailyForecastColumn(forecast: forecast);
                      }).toList(),
                    ),
                    _buildWeeklyTemperatureChart(
                      context,
                      dailyForecasts,
                      totalScrollableWidth,
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

class _DailyForecastColumn extends StatelessWidget {
  final DailyForecast forecast;

  const _DailyForecastColumn({
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    // MODIFIED: Changed icon size from 35.0 to 30.0
    const double iconSize = 30.0;

    final dayIconPath = _getIconAssetPath(forecast.dayIconCode, isNight: false);
    final nightIconPath = _getIconAssetPath(forecast.nightIconCode, isNight: true);

    return SizedBox(
      width: _dailyItemWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            forecast.dayName,
            style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('M/d').format(forecast.date),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          SvgPicture.asset(
            dayIconPath,
            width: iconSize,
            height: iconSize,
            placeholderBuilder: (BuildContext context) => Icon(Icons.wb_cloudy_outlined, size: iconSize, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Text(
            '${forecast.dayTempHigh.round()}°',
            style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 70),
          Text(
            '${forecast.dayTempLow.round()}°', 
            style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (forecast.nightIconCode != null)
            SvgPicture.asset(
              nightIconPath,
              width: iconSize,
              height: iconSize,
              placeholderBuilder: (BuildContext context) => Icon(Icons.wb_cloudy_outlined, size: iconSize, color: Colors.grey),
            )
          else
            SizedBox(height: iconSize),
        ],
      ),
    );
  }
}

// Temperature chart widget remains unchanged
Widget _buildWeeklyTemperatureChart(
  BuildContext context,
  List<DailyForecast> dailyForecasts,
  double totalChartWidth,
) {
  if (dailyForecasts.isEmpty) {
    return const SizedBox.shrink();
  }

  final double dataMinTemp = dailyForecasts.map((f) => f.dayTempLow).reduce((a, b) => a < b ? a : b);
  final double dataMaxTemp = dailyForecasts.map((f) => f.dayTempHigh).reduce((a, b) => a > b ? a : b);

  const double _minChartYSpan = 6.0;
  const double _chartVerticalPadding = 2.0;

  double effectiveMinTemp = dataMinTemp;
  double effectiveMaxTemp = dataMaxTemp;

  if ((dataMaxTemp - dataMinTemp) < _minChartYSpan) {
    final double centerTemp = (dataMinTemp + dataMaxTemp) / 2;
    effectiveMinTemp = centerTemp - (_minChartYSpan / 2);
    effectiveMaxTemp = centerTemp + (_minChartYSpan / 2);
  }

  final List<FlSpot> highTempSpots = dailyForecasts.asMap().entries.map((entry) {
    final index = entry.key;
    final forecast = entry.value;
    final double xPosition = (index * _dailyItemWidth) + (_dailyItemWidth / 2);
    return FlSpot(xPosition, forecast.dayTempHigh.toDouble());
  }).toList();

  final List<FlSpot> lowTempSpots = dailyForecasts.asMap().entries.map((entry) {
    final index = entry.key;
    final forecast = entry.value;
    final double xPosition = (index * _dailyItemWidth) + (_dailyItemWidth / 2);
    return FlSpot(xPosition, forecast.dayTempLow.toDouble());
  }).toList();

  const double chartTopOffset = 125.0;
  const double chartHeight = 70.0;

  return Positioned(
    top: chartTopOffset,
    left: 0,
    width: totalChartWidth,
    height: chartHeight,
    child: LineChart(
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
            spots: highTempSpots,
            isCurved: true,
            color: Colors.deepOrange,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.deepOrange,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: lowTempSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minY: effectiveMinTemp - _chartVerticalPadding,
        maxY: effectiveMaxTemp + _chartVerticalPadding,
        minX: 0,
        maxX: totalChartWidth,
      ),
    ),
  );
}
