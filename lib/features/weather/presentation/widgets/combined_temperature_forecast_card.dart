import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import '../../data/models/weather_data.dart';
// import 'package:intl/intl.dart';
import 'weather_card.dart';

// 輔助函數：構建單個度量項目（圖標、標籤、數值）
Widget _buildMetricItem(IconData icon, String label, Widget valueWidget, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.blueGrey[600],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          valueWidget,
        ],
      ),
    ),
  );
}

// 輔助函數：根據空氣品質等級獲取背景顏色
Color _getAirQualityColor(String? aqiLevel) {
  if (aqiLevel == null) return Colors.grey;
  switch (aqiLevel) {
    case '良好':
      return Colors.green[400]!;
    case '中等':
      return Colors.yellow[700]!;
    case '對敏感族群不健康':
      return Colors.orange[700]!;
    case '不健康':
      return Colors.red[700]!;
    case '非常不健康':
      return Colors.purple[700]!;
    case '危害':
      return Colors.brown[700]!;
    default:
      return Colors.grey;
  }
}

// 輔助函數：根據天氣條件獲取對應的weather_icons圖標
IconData _getWeatherIcon(String condition) {
  final lowerCondition = condition.toLowerCase();
  
  if (lowerCondition.contains('晴') || lowerCondition.contains('陽光')) {
    return WeatherIcons.day_sunny;
  } else if (lowerCondition.contains('多雲')) {
    return WeatherIcons.day_cloudy;
  } else if (lowerCondition.contains('陰')) {
    return WeatherIcons.cloudy;
  } else if (lowerCondition.contains('雷')) {
    return WeatherIcons.thunderstorm;
  } else if (lowerCondition.contains('雨')) {
    return WeatherIcons.rain;
  } else if (lowerCondition.contains('雪')) {
    return WeatherIcons.snow;
  } else if (lowerCondition.contains('霧')) {
    return WeatherIcons.fog;
  } else if (lowerCondition.contains('風')) {
    return WeatherIcons.strong_wind;
  }
  
  // 預設圖標
  return WeatherIcons.day_sunny;
}

// 輔助函數：根據天氣條件獲取圖標顏色
Color _getWeatherIconColor(String condition) {
  final lowerCondition = condition.toLowerCase();
  
  if (lowerCondition.contains('晴') || lowerCondition.contains('陽光')) {
    return Colors.orange[400]!;
  } else if (lowerCondition.contains('多雲') || lowerCondition.contains('陰')) {
    return Colors.grey[500]!;
  } else if (lowerCondition.contains('雷')) {
    return Colors.purple[600]!;
  } else if (lowerCondition.contains('雨')) {
    return Colors.blue[500]!;
  } else if (lowerCondition.contains('雪')) {
    return Colors.lightBlue[200]!;
  } else if (lowerCondition.contains('霧')) {
    return Colors.grey[400]!;
  }
  
  return Colors.orange[400]!;
}

class CombinedTemperatureForecastCard extends StatelessWidget {
  final WeatherInfo data;

  const CombinedTemperatureForecastCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final temperature = data.temperature;
    final feelsLike = data.feelsLike;
    final maxTempYesterday = '${data.tempYesterdayHigh.round()}°';
    final minTempYesterday = '${data.tempYesterdayLow.round()}°';
    final weatherDescription = data.condition;
    final precipitationChance = data.precipitationChance;
    final aqi = data.aqi;
    final aqiLevel = data.aqiLevel;

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主要溫度資訊區域 - 減少padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
            child: Column( // Changed from Row to Column
              children: [
                // First Row: Current Temperature and Weather Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row( // Main temperature - current structure is a Row with Text and Padding for degree
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${temperature.round()}',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w300,
                              color: Colors.black87,
                              height: 0.9,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '°',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: Colors.black54,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container( // Weather Icon
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _getWeatherIcon(weatherDescription),
                          size: 48,
                          color: _getWeatherIconColor(weatherDescription),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8), // Space between the two main rows reduced from 16 to 8

                // Second Row: High/Low Temperature and Weather Description
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container( // High/Low Temperature
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,      
                          children: [
                            Icon(Icons.keyboard_arrow_up, color: Colors.red[400], size: 20),
                            Text(
                              maxTempYesterday,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.keyboard_arrow_down, color: Colors.blue[400], size: 20),
                            Text(
                              minTempYesterday,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text( // Weather Description
                        weatherDescription,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 簡潔的分隔線
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: Colors.grey[200],
          ),

          // 底部指標區域 - 統一間距
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // 體感溫度
                  Expanded(
                    child: _buildMetricItem(
                      Icons.thermostat_outlined,
                      '體感溫度',
                      Text(
                        '${feelsLike.round()}°',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  
                  // 垂直分隔線
                  Container(
                    width: 1,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  
                  // 降雨機率
                  Expanded(
                    child: _buildMetricItem(
                      Icons.water_drop_outlined,
                      '降雨機率',
                      Text(
                        '${precipitationChance}%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  
                  // 垂直分隔線
                  Container(
                    width: 1,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  
                  // 空氣品質 - 移除點擊效果和陰影
                  Expanded(
                    child: _buildMetricItem(
                      Icons.air,
                      '空氣品質',
                      Row( // Changed from Column to Row
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$aqi',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8), // Added horizontal space
                          Container(
                            constraints: const BoxConstraints(maxWidth: 60),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getAirQualityColor(aqiLevel),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              aqiLevel ?? '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}