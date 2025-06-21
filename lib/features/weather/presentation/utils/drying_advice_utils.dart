import 'package:flutter/material.dart';

String getDryingSuggestion({
  required double temp,       // 溫度
  required double humidity,   // 相對濕度 (%)
  required double rainProb,   // 降雨機率 (%)
}) {
  if (rainProb >= 50 || humidity >= 85) {
    return '不宜';
  }
  if (rainProb >= 30 && rainProb < 50) {
    return '注意天氣';
  }
  if (humidity <= 65 && temp >= 25) {
    return '快乾';
  }
  if (humidity <= 75 && temp >= 20) {
    return '普通';
  }
  return '慢乾';
}

int getDryingIndexValue(String dryingSuggestion) {
  switch (dryingSuggestion) {
    case '不宜':
      return 1; // Worst for drying
    case '注意天氣':
      return 2;
    case '慢乾':
      return 3;
    case '普通':
      return 4;
    case '快乾':
      return 5; // Best for drying
    default:
      return 3; // Default or unknown
  }
}

Color getBackgroundColorForDrying(int indexValue) {
  if (indexValue <= 1) {
    return Colors.red.shade200; // Bad
  } else if (indexValue == 2) {
    return Colors.orange.shade200; // Caution
  } else if (indexValue == 3) {
    return Colors.yellow.shade200; // Moderate
  } else if (indexValue >= 4) {
    return Colors.green.shade200; // Good
  } else {
    return Colors.white; // Default
  }
}

String getTemperatureDescription(double temperature) {
  if (temperature < 15) {
    return '溫度偏低';
  } else if (temperature >= 15 && temperature <= 25) {
    return '溫度適中';
  } else {
    return '溫度偏高';
  }
}

String getHumidityDescription(double humidity) {
  if (humidity < 60) {
    return '濕度低';
  } else if (humidity >= 60 && humidity <= 80) {
    return '濕度普通';
  } else {
    return '濕度高';
  }
}

String getPrecipitationDescription(double precipitationChance) {
  if (precipitationChance < 30) {
    return '降雨機率低';
  } else if (precipitationChance >= 30 && precipitationChance <= 50) {
    return '降雨機率中等';
  } else {
    return '降雨機率高';
  }
}
