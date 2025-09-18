import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'weather_card.dart';
import '../utils/weather_icon_mapper.dart';

Widget _buildMetricItem(IconData icon, String label, Widget valueWidget, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Colors.blueGrey[600]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          valueWidget,
        ],
      ),
    ),
  );
}

Color _getAirQualityColor(String? aqiLevel) {
  if (aqiLevel == null) return Colors.grey;
  switch (aqiLevel) {
    case '良好': return Colors.green[400]!;
    case '普通': return Colors.yellow[700]!;
    case '對敏感族群不健康': return Colors.orange[700]!;
    case '不健康': return Colors.red[700]!;
    case '非常不健康': return Colors.purple[700]!;
    case '危害': return Colors.brown[700]!;
    default: return Colors.grey;
  }
}

String _getIconAssetPath(String? description, {required bool isNight}) {
  const String basePath = kIsWeb ? 'assets/assets/icons/' : 'assets/icons/';
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

class CombinedTemperatureForecastCard extends StatelessWidget {
  final String? condition;
  final String? conditionIcon;
  final double? temperature;
  final double? feelsLike;
  final double? tempHigh;
  final double? tempLow;
  final int? precipitationChance;
  final int? aqi;
  final String? aqiLevel;
  final bool isDaytime;

  const CombinedTemperatureForecastCard({
    super.key,
    this.condition,
    this.conditionIcon,
    this.temperature,
    this.feelsLike,
    this.tempHigh,
    this.tempLow,
    this.precipitationChance,
    this.aqi,
    this.aqiLevel,
    this.isDaytime = true,
  });

  @override
  Widget build(BuildContext context) {
    final weatherDescription = condition ?? 'N/A';
    final temp = temperature ?? 0;
    final feels = feelsLike ?? 0;
    final maxTemp = tempHigh ?? 0;
    final minTemp = tempLow ?? 0;
    final precip = precipitationChance ?? 0;
    final aqiValue = aqi ?? 0;

    final iconDescription = conditionIcon ?? condition;
    final iconPath = _getIconAssetPath(iconDescription, isNight: !isDaytime);

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${temp.round()}',
                            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w300, color: Colors.black87, height: 0.9),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text('°', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.black54, height: 1.0)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          iconPath,
                          width: 56, // MODIFIED: Increased size from 48 to 64
                          height: 56, // MODIFIED: Increased size from 48 to 64
                          placeholderBuilder: (BuildContext context) => Icon(Icons.wb_cloudy_outlined, size: 56, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard_arrow_up, color: Colors.red[400], size: 20),
                            Text('${maxTemp.round()}°', style: TextStyle(fontSize: 15, color: Colors.red[400], fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Icon(Icons.keyboard_arrow_down, color: Colors.blue[400], size: 20),
                            Text('${minTemp.round()}°', style: TextStyle(fontSize: 15, color: Colors.blue[400], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        weatherDescription,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: Colors.grey[200],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      Icons.thermostat_outlined,
                      '體感溫度',
                      Text('${feels.round()}°', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ),
                  ),
                  Container(width: 1, color: Colors.grey[200], margin: const EdgeInsets.symmetric(vertical: 12)),
                  Expanded(
                    child: _buildMetricItem(
                      Icons.water_drop_outlined,
                      '降雨機率',
                      Text('$precip%', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ),
                  ),
                  Container(width: 1, color: Colors.grey[200], margin: const EdgeInsets.symmetric(vertical: 12)),
                  Expanded(
                    child: _buildMetricItem(
                      Icons.air,
                      '空氣品質',
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$aqiValue', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 60),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _getAirQualityColor(aqiLevel), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              aqiLevel ?? '未知',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
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
