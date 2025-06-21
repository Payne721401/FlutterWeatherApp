import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/weather_data.dart';
// import '../utils/weather_utils.dart';
import 'weather_card.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this import

const double _hourlyItemWidth = 80.0; // 固定每個小時預報項目的寬度

// Moved from combined_temperature_forecast_card.dart
Widget _buildCombinedHourlyItem(BuildContext context, HourlyForecast forecast) {
  final formattedTime = DateFormat.Hm().format(forecast.time);
  final temperatureText = '${forecast.temperature.round()}°';
  final chanceOfRainText = '${forecast.precipitationChance}%';

  // 根據溫度設定背景顏色（仿照範例圖的彩色溫度標籤）
  Color tempBackgroundColor;
  if (forecast.temperature >= 30) {
    tempBackgroundColor = Colors.red[400]!;
  } else if (forecast.temperature >= 25) {
    tempBackgroundColor = Colors.orange[400]!;
  } else if (forecast.temperature >= 20) {
    tempBackgroundColor = Colors.yellow[700]!;
  } else if (forecast.temperature >= 15) {
    tempBackgroundColor = Colors.green[400]!;
  } else {
    tempBackgroundColor = Colors.blue[400]!;
  }

  return SizedBox( // 從 Expanded 改為 SizedBox，設定固定寬度
    width: _hourlyItemWidth,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 天氣圖標移到最上方（仿照範例圖結構）
        Icon(
          Icons.cloud, // TODO: Use actual weather icon
          size: 24,
          color: Colors.blueGrey[600],
        ),
        
        const SizedBox(height: 4),
        
        // 降雨機率
        Text(
          chanceOfRainText,
          style: TextStyle(
            fontSize: 11, 
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 45), // 增加曲線空間
        
        // 溫度 - 使用彩色圓角背景（仿照範例圖風格）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: tempBackgroundColor,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            temperatureText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 時間
        Text(
          formattedTime,
          style: TextStyle(
            fontSize: 11, 
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// Moved from combined_temperature_forecast_card.dart
// 調整溫度曲線位置以配合新的佈局
Widget _buildTemperatureChart(
  BuildContext context,
  List<HourlyForecast> chartForecasts, // 直接接收已過濾的預報列表
  double totalChartWidth, // 接收計算後的總寬度
) {
  if (chartForecasts.isEmpty) {
    return const SizedBox.shrink();
  }

  final double minTemp = chartForecasts
      .map((f) => f.temperature)
      .reduce((a, b) => a < b ? a : b);
  final double maxTemp = chartForecasts
      .map((f) => f.temperature)
      .reduce((a, b) => a > b ? a : b);

  const double itemWidth = _hourlyItemWidth; // 使用固定的項目寬度
  
  final spots = chartForecasts.asMap().entries.map((entry) {
    final index = entry.key;
    final forecast = entry.value;
    // xPosition 位於每個項目寬度的中心
    final double xPosition = (index * itemWidth) + (itemWidth / 2);
    return FlSpot(
      xPosition,
      forecast.temperature.toDouble(),
    );
  }).toList();

  // 重新計算曲線位置：圖標(24) + 間距(4) + 降雨機率(11) + 間距的一半 = 約50px
  const double chartTopOffset = 50.0;
  const double chartHeight = 40.0;

  return Positioned(
    top: chartTopOffset,
    left: 0,
    // right: 0, // 移除 right，改用 width 確保正確寬度
    width: totalChartWidth, // 設定 LineChart 的寬度為滾動內容的總寬度
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
            spots: spots,
            isCurved: true,
            color: Colors.grey[400]!, // 使用更柔和的灰色
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.grey[400]!,
                  strokeColor: Colors.white,
                  strokeWidth: 1,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minY: minTemp - (maxTemp - minTemp) * 0.4,
        maxY: maxTemp + (maxTemp - minTemp) * 0.4,
        minX: 0,
        maxX: totalChartWidth, // maxX 需與總寬度一致
      ),
    ),
  );
}

class HourlyForecastCard extends StatelessWidget {
  final List<HourlyForecast> hourlyForecasts;

  const HourlyForecastCard({super.key, required this.hourlyForecasts});

  @override
  Widget build(BuildContext context) {
    // 計算滾動內容的總寬度
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
                height: 150, // 調整高度以配合新的曲線空間
                width: totalScrollableWidth, // Stack 的寬度為所有項目寬度之和
                child: Stack(
                  children: [
                    // 預報項目行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: hourlyForecasts
                          .map((forecast) => _buildCombinedHourlyItem(context, forecast))
                          .toList(),
                    ),
                    
                    // 溫度曲線圖
                    _buildTemperatureChart(
                      context,
                      hourlyForecasts, // 傳遞完整的預報列表
                      totalScrollableWidth, // 傳遞總寬度
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
