import 'package:flutter/material.dart';
import '../../data/models/weather_data.dart';
import 'parameter_bar_chart.dart'; // Import the ParameterBarChart
import '../utils/clothing_advice_utils.dart'; // Import the new utility file

class ClothingAdviceDialog extends StatelessWidget {
  final WeatherInfo data;

  const ClothingAdviceDialog({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define color stops for clothing advice parameters with vivid colors
    final feelsLikeColors = [
      ColorStop(10.0, const Color.fromARGB(255, 32, 140, 248)), // <10 too cold
      ColorStop(15.0, Colors.green), // 10-15 cool (needs attention)
      ColorStop(26.0, Colors.yellow), // 15-26 comfortable
      ColorStop(30.0, Colors.orange), // 26-30 warm (needs attention)
      ColorStop(double.infinity, Colors.red), // >30 hot (warning)
    ];
    // Define color stops for temperature difference
    final tempDiffColors = [
      ColorStop(3.0, Colors.green), // <3 small difference (comfortable)
      ColorStop(7.0, Colors.yellow), // 3-7 moderate difference (needs attention)
      ColorStop(double.infinity, Colors.red), // >7 large difference (warning)
    ];

    // Calculate temperature difference using available data
    final tempDifference = (data.tempHigh - data.tempLow).abs();
    final outfitSuggestion = generateOutfitSuggestion(data.feelsLike.toDouble(), tempDifference.toDouble());


    return AlertDialog(
      backgroundColor: Colors.white, // Set background color to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20.0),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: getBackgroundColorForFeelsLike(data.feelsLike.toDouble()), // Set title background color based on feelsLike
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
                  Text(
                    '穿搭建議',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black), // Title text color black for contrast
                  ),
                  const SizedBox(height: 4), // Added space below title
                  Text(
                    outfitSuggestion, // Display outfit suggestion here
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87), // Stronger style
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 體感溫度
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat_outlined, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('體感溫度', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: data.feelsLike.toDouble(),
                        maxValue: 35.0, // Assuming a max felt temperature for the chart scale
                        colorStops: feelsLikeColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${data.feelsLike}°C', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   ],
                 ),
                 const SizedBox(height: 4), // Added space below the bar chart
                 Row(
                   children: [
                     Text(getFeelsLikeDescription(data.feelsLike.toDouble()), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                   ],
                 ),
                 const SizedBox(height: 16),
              ],
            ),

            // 溫差
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                     Icon(Icons.show_chart, color: Colors.purple),
                     const SizedBox(width: 8),
                     Text('溫差', style: Theme.of(context).textTheme.titleMedium),
                   ],
                 ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: tempDifference.toDouble(),
                        maxValue: 15.0, // Assuming a max temperature difference for the chart scale
                        colorStops: tempDiffColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${tempDifference.toStringAsFixed(1)}°C', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   ],
                 ),
                const SizedBox(height: 4), // Added space below the bar chart
                 Row(
                   children: [
                      Text(getTempDiffDescription(tempDifference.toDouble()), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                   ],
                 ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}