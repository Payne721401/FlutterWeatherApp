import 'package:flutter/material.dart';
import 'weather_card.dart';
import 'horizontal_bar_chart.dart';
import 'clothing_advice_dialog.dart';
import 'drying_index_dialog.dart';
import 'outdoor_sports_dialog.dart';
import '../utils/clothing_advice_utils.dart';
import '../utils/drying_advice_utils.dart';
import '../utils/exercise_advice_utils.dart';

// 1. Define the new, independent data class.
// This class is self-contained and has no external dependencies.
class IndicesCardDialogData {
  final double temperature;
  final double feelsLike;
  final double tempHigh;
  final double tempLow;
  final int humidity;
  final int precipitationChance;
  final int aqi;
  final int uvIndex;
  final double windSpeed;

  IndicesCardDialogData({
    required this.temperature,
    required this.feelsLike,
    required this.tempHigh,
    required this.tempLow,
    required this.humidity,
    required this.precipitationChance,
    required this.aqi,
    required this.uvIndex,
    required this.windSpeed,
  });
}

class IndicesCard extends StatelessWidget {
  final double? temperature;
  final double? feelsLike;
  final double? tempHigh;
  final double? tempLow;
  final int? humidity;
  final int? precipitationChance;
  final int? aqi;
  final int? uvIndex;
  final double? windSpeed;

  const IndicesCard({
    super.key,
    this.temperature,
    this.feelsLike,
    this.tempHigh,
    this.tempLow,
    this.humidity,
    this.precipitationChance,
    this.aqi,
    this.uvIndex,
    this.windSpeed,
  });

  // Helper for Advice Items
  Widget _buildAdviceItem(BuildContext context, IconData icon, String title, String advice, int value, int maxValue, VoidCallback onTap) {
     final suitabilityColors = [Colors.green, Colors.greenAccent, Colors.yellow, Colors.orange, Colors.red];
     final percentage = value / maxValue;
     Color itemBarColor = _getColorForSuitability(percentage, suitabilityColors);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                child: Icon(icon, size: 24, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]), textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(advice, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              HorizontalBarChart(
                value: value.toDouble(),
                maxValue: maxValue.toDouble(),
                barColor: itemBarColor,
                width: 60,
              ),
               Text(
                 '($value/$maxValue)',
                 style: TextStyle(fontSize: 10, color: Colors.grey[600])
               ),
            ],
          ),
        ),
      ),
    );
  }

   Color _getColorForSuitability(double percentage, List<Color> colors) {
     if (percentage <= 0.0) return colors.first;
     if (percentage >= 1.0) return colors.last;
     final section = 1.0 / (colors.length - 1);
     int startIndex = (percentage / section).floor().clamp(0, colors.length - 1);
     int endIndex = (percentage / section).ceil().clamp(0, colors.length - 1);
     if (startIndex == endIndex) return colors[startIndex];
     final sectionPercentage = (percentage - startIndex * section) / section;
     return Color.lerp(colors[startIndex], colors[endIndex], sectionPercentage)!;
   }

  @override
  Widget build(BuildContext context) {
    const int maxIndexValue = 5;

    // Use null-coalescing for safety.
    final currentFeelsLike = feelsLike ?? 0.0;
    final currentTempHigh = tempHigh ?? 0.0;
    final currentTempLow = tempLow ?? 0.0;
    final currentTemperature = temperature ?? 0.0;
    final currentHumidity = humidity ?? 0;
    final currentPrecipitationChance = precipitationChance ?? 0;
    final currentWindSpeed = windSpeed ?? 0.0;
    final currentAqi = aqi ?? 0;
    final currentUvIndex = uvIndex ?? 0;

    // Calculate advice values
    final tempDifference = (currentTempHigh - currentTempLow).abs();
    final outfitSuggestion = generateOutfitSuggestion(currentFeelsLike, tempDifference);
    final clothingIndexValue = getClothingIndexValue(outfitSuggestion);
    final dryingSuggestion = getDryingSuggestion(
      temp: currentTemperature,
      humidity: currentHumidity.toDouble(),
      rainProb: currentPrecipitationChance.toDouble(),
    );
    final dryingIndexValue = getDryingIndexValue(dryingSuggestion);
    final exerciseSuggestion = getExerciseSuggestion(
      temp: currentFeelsLike,
      windLevel: currentWindSpeed,
      aqi: currentAqi,
      rainProb: currentPrecipitationChance.toDouble(),
      uvIndex: currentUvIndex,
    );
    final exerciseIndexValue = getExerciseIndexValue(exerciseSuggestion);
    
    // 2. Create an instance of the new data class.
    // This object is what will be passed to the dialogs.
    final dialogData = IndicesCardDialogData(
      temperature: currentTemperature,
      feelsLike: currentFeelsLike,
      tempHigh: currentTempHigh,
      tempLow: currentTempLow,
      humidity: currentHumidity,
      precipitationChance: currentPrecipitationChance,
      aqi: currentAqi,
      uvIndex: currentUvIndex,
      windSpeed: currentWindSpeed,
    );

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdviceItem(context, Icons.checkroom, '穿搭建議', outfitSuggestion, clothingIndexValue, maxIndexValue,
                 () => showDialog(context: context, builder: (_) => ClothingAdviceDialog(data: dialogData))),
              _buildAdviceItem(context, Icons.wb_sunny_outlined, '曬衣建議', dryingSuggestion, dryingIndexValue, maxIndexValue,
                 () => showDialog(context: context, builder: (_) => DryingIndexDialog(data: dialogData))),
              _buildAdviceItem(context, Icons.directions_run, '戶外運動', exerciseSuggestion, exerciseIndexValue, maxIndexValue,
                 () => showDialog(context: context, builder: (_) => OutdoorSportsDialog(data: dialogData))),
            ]
          ),
        ],
      )
    );
  }
}
