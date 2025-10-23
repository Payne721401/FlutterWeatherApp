import 'package:flutter/material.dart';

String generateOutfitSuggestion(double temp, double diff) {
  if (temp <= 10) return '厚外套';
  if (temp <= 15) {
    return diff >= 10 ? '厚外套' : '長袖+外套';
  }
  if (temp <= 22) {
    if (diff >= 10) return '長袖+外套';
    if (diff >= 6) return '長袖+薄外套';
    return '長袖';
  }
  if (temp <= 27) {
    return '短袖+薄外套';
  }
  // temp > 27
  if (diff >= 10) return '短袖+薄外套';
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
  if (tempDiff < 5) {
    return '溫差小';
  } else if (tempDiff >= 5 && tempDiff < 10) {
    return '溫差中等';
  } else {
    return '溫差大';
  }
}

Color getBackgroundColorForFeelsLike(double feelsLike) {
    if (feelsLike <= 10) {
      return Colors.blue.shade200;
    } else if (feelsLike <= 15) {
      return Colors.lightBlue.shade200;
    } else if (feelsLike <= 22) {
      return Colors.green.shade200;
    } else if (feelsLike <= 27) {
      return Colors.yellow.shade200;
    } else { // > 27
      return Colors.red.shade200;
    }
  }
