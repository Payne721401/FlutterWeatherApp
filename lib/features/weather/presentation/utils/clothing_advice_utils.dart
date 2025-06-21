import 'package:flutter/material.dart';

String generateOutfitSuggestion(double temp, double diff) {
  if (temp <= 10) return '厚外套';
  if (temp <= 15) {
    return diff >= 8 ? '厚外套' : '長袖+外套';
  }
  if (temp <= 22) {
    if (diff >= 8) return '長袖+外套';
    if (diff >= 6) return '長袖+薄外套';
    return '長袖';
  }
  if (temp <= 27) {
    if (diff >= 8) return '短袖+薄外套';
    return '短袖';
  }
  // temp ≥ 28
  if (diff >= 8) return '短袖+薄外套';
  return '短袖';
}

int getClothingIndexValue(String outfitSuggestion) {
  switch (outfitSuggestion) {
    case '厚外套':
      return 1; // Coldest
    case '長袖+外套':
      return 2;
    case '長袖+薄外套':
      return 3;
    case '長袖':
      return 4;
    case '短袖+薄外套': // Can be slightly warmer than just long sleeves, but still needs a light layer
      return 4;
    case '短袖':
      return 5; // Warmest
    default:
      return 3; // Default or unknown
  }
}

String getFeelsLikeDescription(double feelsLike) {
  if (feelsLike < 15) {
    return '寒冷';
  } else if (feelsLike >= 15 && feelsLike <= 26) {
    return '舒適';
  } else if (feelsLike > 26 && feelsLike <= 30) {
    return '溫暖';
  } else {
    return '炎熱';
  }
}

String getTempDiffDescription(double tempDiff) {
  if (tempDiff < 3) {
    return '溫差小';
  } else if (tempDiff >= 3 && tempDiff <= 7) {
    return '溫差普通';
  } else {
    return '溫差大';
  }
}

Color getBackgroundColorForFeelsLike(double feelsLike) {
    // Define color stops from cold (blue) to hot (orange-red)
    // Values are approximate temperature points
    if (feelsLike <= 10) {
      return Colors.blue.shade200; // Very cold
    } else if (feelsLike <= 15) {
      return Colors.blue.shade100; // Cold
    } else if (feelsLike <= 20) {
      return Colors.lightBlue.shade100; // Cool
    } else if (feelsLike <= 25) {
      return Colors.lightGreen.shade100; // Comfortable
    } else if (feelsLike <= 30) {
      return Colors.orange.shade100; // Warm
    } else {
      return Colors.red.shade100; // Hot
    }
  }