import 'package:flutter/material.dart';
import 'weather_card.dart';
import 'clothing_advice_dialog.dart';
import 'drying_index_dialog.dart';
import 'outdoor_sports_dialog.dart';
import '../utils/clothing_advice_utils.dart';
import '../utils/drying_advice_utils.dart';
import '../utils/exercise_advice_utils.dart';

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

  Widget _buildAdviceItem(BuildContext context, IconData icon, String title, String advice, Color backgroundColor, VoidCallback onTap) {
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
              const SizedBox(height: 4), // MODIFIED: Increased spacing from 2 to 4
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  advice,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getClothingAdviceBackgroundColor(String advice) {
    if (advice.contains('短袖')) return Colors.red.shade400;
    if (advice.contains('厚外套') || advice.contains('長袖+外套')) return Colors.blue.shade400;
    return Colors.green.shade400;
  }

  Color _getDryingAdviceBackgroundColor(String advice) {
    if (advice.contains('快乾') || advice.contains('普通')) return Colors.green.shade400;
    if (advice.contains('不宜')) return Colors.red.shade400;
    return Colors.yellow.shade800;
  }

  Color _getExerciseAdviceBackgroundColor(String advice) {
    if (advice.contains('適合運動') || advice.contains('非常適合')) return Colors.green.shade400;
    if (advice.contains('不宜運動')) return Colors.red.shade400;
    return Colors.yellow.shade800;
  }

  @override
  Widget build(BuildContext context) {
    final currentFeelsLike = feelsLike ?? 0.0;
    final currentTempHigh = tempHigh ?? 0.0;
    final currentTempLow = tempLow ?? 0.0;
    final currentTemperature = temperature ?? 0.0;
    final currentHumidity = humidity ?? 0;
    final currentPrecipitationChance = precipitationChance ?? 0;
    final currentWindSpeed = windSpeed ?? 0.0;
    final currentAqi = aqi ?? 0;
    final currentUvIndex = uvIndex ?? 0;

    final tempDifference = (currentTempHigh - currentTempLow).abs();
    final outfitSuggestion = generateOutfitSuggestion(currentFeelsLike, tempDifference);
    final dryingSuggestion = getDryingSuggestion(
      temp: currentTemperature,
      humidity: currentHumidity.toDouble(),
      rainProb: currentPrecipitationChance.toDouble(),
    );
    final exerciseSuggestion = getExerciseSuggestion(
      temp: currentFeelsLike,
      windLevel: currentWindSpeed,
      aqi: currentAqi,
      rainProb: currentPrecipitationChance.toDouble(),
      uvIndex: currentUvIndex,
    );
    
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
              _buildAdviceItem(context, Icons.checkroom, '穿搭建議', outfitSuggestion,
                 _getClothingAdviceBackgroundColor(outfitSuggestion),
                 () => showDialog(context: context, builder: (_) => ClothingAdviceDialog(data: dialogData))),
              _buildAdviceItem(context, Icons.wb_sunny_outlined, '曬衣建議', dryingSuggestion,
                 _getDryingAdviceBackgroundColor(dryingSuggestion),
                 () => showDialog(context: context, builder: (_) => DryingIndexDialog(data: dialogData))),
              _buildAdviceItem(context, Icons.directions_run, '戶外運動', exerciseSuggestion,
                 _getExerciseAdviceBackgroundColor(exerciseSuggestion),
                 () => showDialog(context: context, builder: (_) => OutdoorSportsDialog(data: dialogData))),
            ]
          ),
        ],
      )
    );
  }
}
