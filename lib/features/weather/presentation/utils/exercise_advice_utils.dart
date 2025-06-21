import 'package:flutter/material.dart';

String getExerciseSuggestion({
  required double temp,
  required double windLevel,
  required int aqi,
  required double rainProb,
  required int uvIndex,
}) {
  // Step 1: 強烈不建議
  if (rainProb >= 50 || aqi >= 151 || temp >= 34 || temp <= 10 || windLevel >= 6) {
    return '不宜運動';
  }

  // Step 2: 注意氣候
  if (uvIndex >= 7 || windLevel >= 4 || aqi >= 101 || temp >= 30 || temp <= 15) {
    return '注意天氣';
  }

  // Step 3: 非常適合 vs 適合
  if (rainProb < 10 && aqi < 50 && uvIndex < 5 && windLevel <= 2 && temp >= 20 && temp <= 30) {
    return '非常適合';
  }

  return '適合運動';
}

int getExerciseIndexValue(String exerciseSuggestion) {
  switch (exerciseSuggestion) {
    case '不宜運動':
      return 1; // Least suitable
    case '注意天氣':
      return 2;
    case '適合運動':
      return 4;
    case '非常適合':
      return 5; // Most suitable
    default:
      return 3; // Default or unknown
  }
}

Color getBackgroundColorForExercise(int indexValue) {
  if (indexValue <= 1) {
    return Colors.red.shade200; // Bad
  } else if (indexValue == 2) {
    return Colors.orange.shade200; // Caution
  } else if (indexValue >= 4) {
    return Colors.green.shade200; // Good
  } else {
    return Colors.yellow.shade200; // Moderate (for default or other cases)
  }
}

String getAQIDescription(int aqi) {
  if (aqi <= 50) {
    return '空氣品質良好';
  } else if (aqi <= 100) {
    return '空氣品質普通';
  } else if (aqi <= 150) {
    return '對敏感族群不健康';
  } else if (aqi <= 200) {
    return '不健康';
  } else if (aqi <= 300) {
    return '非常不健康';
  } else {
    return '危害';
  }
}

String getUVIndexDescription(int uvIndex) {
  if (uvIndex <= 2) {
    return '低量級';
  } else if (uvIndex <= 5) {
    return '中量級';
  } else if (uvIndex <= 7) {
    return '高量級';
  } else if (uvIndex <= 10) {
    return '過量級';
  } else {
    return '危險級';
  }
}

String getWindLevelDescription(double windLevel) {
  if (windLevel < 4) {
    return '風力輕微';
  } else if (windLevel < 6) {
    return '風力較強';
  } else {
    return '風力強勁';
  }
}

String getTemperatureForExerciseDescription(double temperature) {
    if (temperature <= 10) {
      return '寒冷';
    } else if (temperature <= 15) {
      return '偏冷';
    } else if (temperature >= 34) {
      return '炎熱';
    } else if (temperature >= 30) {
      return '偏熱';
    } else if (temperature >= 20 && temperature <= 30) {
      return '舒適';
    } else {
      return '一般';
    }
}

String getPrecipitationDescription(double precipitationChance) {
  if (precipitationChance <= 10) {
    return '機率極低';
  } else if (precipitationChance <= 30) {
    return '機率較低';
  } else if (precipitationChance <= 50) {
    return '機率中等';
  } else {
    return '機率偏高';
  }
}
