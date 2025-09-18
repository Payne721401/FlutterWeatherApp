import 'package:flutter/material.dart';
import 'indices_card.dart'; // Import the file with the new data class
import 'parameter_bar_chart.dart';
import '../utils/clothing_advice_utils.dart';

class ClothingAdviceDialog extends StatelessWidget {
  // Use the new, independent data class
  final IndicesCardDialogData data;

  const ClothingAdviceDialog({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define color stops for clothing advice parameters
    final feelsLikeColors = [
      ColorStop(10.0, const Color.fromARGB(255, 32, 140, 248).withOpacity(0.7)), // <10
      ColorStop(15.0, Colors.green.shade400), // 10-15
      ColorStop(26.0, Colors.yellow.shade400), // 15-26
      ColorStop(30.0, Colors.orange.shade400), // 26-30
      ColorStop(double.infinity, Colors.red.shade400), // >30
    ];
    final tempDiffColors = [
      ColorStop(5.0, Colors.green.shade400), // <5
      ColorStop(10.0, Colors.yellow.shade400), // 5-10
      ColorStop(double.infinity, Colors.red.shade400), // >7
    ];

    // Calculate temperature difference using data from the new class
    final tempDifference = (data.tempHigh - data.tempLow).abs();
    final outfitSuggestion = generateOutfitSuggestion(data.feelsLike, tempDifference);

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
          color: getBackgroundColorForFeelsLike(data.feelsLike),
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
              child: Icon(Icons.checkroom, size: 28, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('穿搭建議', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(outfitSuggestion, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
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
            _buildDetailItem(context, '目前體感溫度', Icons.thermostat_outlined, Colors.blue, data.feelsLike, 50.0, feelsLikeColors, '°C', getFeelsLikeDescription),
            _buildDetailItem(context, '溫差', Icons.show_chart, Colors.purple, tempDifference, 15.0, tempDiffColors, '°C', getTempDiffDescription),
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
            SizedBox(
              width: 75.0,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('${value.toStringAsFixed(1)}$unit', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
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
