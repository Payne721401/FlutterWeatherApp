import 'package:flutter/material.dart';
import 'indices_card.dart'; // Import the file with the new data class
import 'parameter_bar_chart.dart';
import '../utils/drying_advice_utils.dart';

class DryingIndexDialog extends StatelessWidget {
  // Use the new, independent data class
  final IndicesCardDialogData data;

  const DryingIndexDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Define color stops for drying index parameters with vivid colors
    final temperatureColors = [
      ColorStop(15.0, Colors.red), // <15 red
      ColorStop(25.0, Colors.yellow), // 15-25 yellow
      ColorStop(double.infinity, Colors.green), // >25 green
    ];
    final humidityColors = [
      ColorStop(60.0, Colors.green), // <60 green
      ColorStop(80.0, Colors.yellow), // 60-80 yellow
      ColorStop(double.infinity, Colors.red), // >80 red
    ];
    final precipitationColors = [
      ColorStop(30.0, Colors.green), // <30 green
      ColorStop(60.0, Colors.yellow), // 30-60 yellow
      ColorStop(double.infinity, Colors.red), // >60 red
    ];

    // Calculate drying advice using data from the new class
    final dryingSuggestion = getDryingSuggestion(
      temp: data.temperature,
      humidity: data.humidity.toDouble(),
      rainProb: data.precipitationChance.toDouble(),
    );
    final dryingIndexValue = getDryingIndexValue(dryingSuggestion);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20.0),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: getBackgroundColorForDrying(dryingIndexValue),
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
              child: Icon(Icons.wb_sunny_outlined, size: 28, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('曬衣指數', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(dryingSuggestion, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
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
            // 溫度
            _buildDetailItem(context, '溫度', Icons.thermostat_outlined, Colors.redAccent, data.temperature, 40.0, temperatureColors, '°C', getTemperatureDescription),
            // 濕度
            _buildDetailItem(context, '濕度', Icons.water_drop_outlined, Colors.lightBlue, data.humidity.toDouble(), 100.0, humidityColors, '%', getHumidityDescription),
            // 降雨機率
            _buildDetailItem(context, '降雨機率', Icons.umbrella_outlined, Colors.grey, data.precipitationChance.toDouble(), 100.0, precipitationColors, '%', getPrecipitationDescription),
          ],
        ),
      ),
    );
  }

  // Helper widget to reduce code duplication
  Widget _buildDetailItem(BuildContext context, String title, IconData icon, Color iconColor, double value, double maxValue, List<ColorStop> colorStops, String unit, Function(double) getDescription) {
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
