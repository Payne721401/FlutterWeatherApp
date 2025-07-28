import 'package:flutter/material.dart';
import 'indices_card.dart'; // Import the file with the new data class
import 'parameter_bar_chart.dart';
import '../utils/exercise_advice_utils.dart';

class OutdoorSportsDialog extends StatelessWidget {
  // Use the new, independent data class
  final IndicesCardDialogData data;

  const OutdoorSportsDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Define color stops for outdoor sports parameters
    final feelsLikeColors = [
      ColorStop(10.0, Colors.red), ColorStop(15.0, Colors.orange), ColorStop(20.0, Colors.yellow),
      ColorStop(30.0, Colors.green), ColorStop(34.0, Colors.orange), ColorStop(double.infinity, Colors.red),
    ];
    final windSpeedColors = [
      ColorStop(2.0, Colors.green), ColorStop(4.0, Colors.yellow), ColorStop(6.0, Colors.orange),
      ColorStop(double.infinity, Colors.red),
    ];
    final aqiColors = [
      ColorStop(50.0, Colors.green), ColorStop(100.0, Colors.yellow), ColorStop(150.0, Colors.orange),
      ColorStop(double.infinity, Colors.red),
    ];
    final precipitationColors = [
      ColorStop(10.0, Colors.green), ColorStop(30.0, Colors.yellow), ColorStop(50.0, Colors.orange),
      ColorStop(double.infinity, Colors.red),
    ];
    final uvIndexColors = [
      ColorStop(2.0, Colors.green), ColorStop(5.0, Colors.yellow), ColorStop(7.0, Colors.orange),
      ColorStop(double.infinity, Colors.red),
    ];

    // Calculate exercise advice using data from the new class
    final exerciseSuggestion = getExerciseSuggestion(
      temp: data.feelsLike,
      windLevel: data.windSpeed,
      aqi: data.aqi,
      rainProb: data.precipitationChance.toDouble(),
      uvIndex: data.uvIndex,
    );
    final exerciseIndexValue = getExerciseIndexValue(exerciseSuggestion);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20.0),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: getBackgroundColorForExercise(exerciseIndexValue),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
              child: Icon(Icons.directions_run, size: 28, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('戶外運動', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(exerciseSuggestion, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailItem(context, '體感溫度', Icons.thermostat_outlined, Colors.redAccent, data.feelsLike, 40.0, feelsLikeColors, '°C', (v) => getTemperatureForExerciseDescription(v)),
            _buildDetailItem(context, '風速', Icons.wind_power, Colors.blueGrey, data.windSpeed, 7.0, windSpeedColors, ' 級', (v) => getWindLevelDescription(v)),
            _buildDetailItem(context, '空氣品質(AQI)', Icons.air, Colors.teal, data.aqi.toDouble(), 200.0, aqiColors, '', (v) => getAQIDescription(v.toInt())),
            _buildDetailItem(context, '降雨機率', Icons.umbrella_outlined, Colors.grey, data.precipitationChance.toDouble(), 100.0, precipitationColors, '%', (v) => getPrecipitationDescription(v)),
            _buildDetailItem(context, '紫外線', Icons.wb_sunny, Colors.amber, data.uvIndex.toDouble(), 11.0, uvIndexColors, '', (v) => getUVIndexDescription(v.toInt())),
          ],
        ),
      ),
    );
  }

  // Helper widget to reduce code duplication
  Widget _buildDetailItem(BuildContext context, String title, IconData icon, Color iconColor, double value, double maxValue, List<ColorStop> colorStops, String unit, String Function(dynamic) getDescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ParameterBarChart(
                value: value,
                maxValue: maxValue,
                colorStops: colorStops,
                height: 10.0,
                width: double.infinity,
              ),
            ),
            const SizedBox(width: 8),
            Text('${value.toStringAsFixed(unit == "°C" ? 1 : 0)}$unit', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(getDescription(value), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
