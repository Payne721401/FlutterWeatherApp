import 'package:flutter/material.dart';
import '../../data/models/weather_data.dart';
import 'parameter_bar_chart.dart'; // Import the new parameter bar chart
import '../utils/drying_advice_utils.dart'; // Import the new utility file

class DryingIndexDialog extends StatelessWidget {
  final WeatherInfo data;

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
      ColorStop(60.0, Colors.yellow), // 30-60 yellow (adjusted to match user's 40-50 broadly)
      ColorStop(double.infinity, Colors.red), // >60 red
    ];

    // Calculate drying advice based on the new logic
    final dryingSuggestion = getDryingSuggestion(
      temp: data.temperature.toDouble(),
      humidity: data.humidity.toDouble(),
      rainProb: data.precipitationChance.toDouble(),
    );
    final dryingIndexValue = getDryingIndexValue(dryingSuggestion);

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
          color: getBackgroundColorForDrying(dryingIndexValue), // Set title background color based on drying index
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
                  Text(
                    '曬衣指數',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black), // Title text color black for contrast
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dryingSuggestion, // Display drying suggestion here
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
            // 溫度
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat_outlined, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text('溫度', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: data.temperature.toDouble(),
                        maxValue: 40.0, // Adjusted example max value for temperature
                        colorStops: temperatureColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${data.temperature}°C', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                 const SizedBox(height: 4), // Added space below the bar chart
                 Row(
                   children: [
                     Text(getTemperatureDescription(data.temperature.toDouble()), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                   ],
                 ),
                 const SizedBox(height: 16),
              ],
            ),

            // Removed Wind Speed section

            // 濕度
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                     Icon(Icons.water_drop_outlined, color: Colors.lightBlue),
                     const SizedBox(width: 8), // Added SizedBox for consistent spacing
                     Text('濕度', style: Theme.of(context).textTheme.titleMedium),
                   ],
                 ),
                const SizedBox(height: 8),
                 Row(
                   children: [
                     Expanded(
                       child: ParameterBarChart(
                         value: data.humidity.toDouble(),
                         maxValue: 100.0, // Max humidity is 100%
                         colorStops: humidityColors,
                         height: 10.0,
                         width: double.infinity,
                       ),
                     ),
                    const SizedBox(width: 8),
                     Text('${data.humidity}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   ],
                 ),
                 const SizedBox(height: 4), // Added space below the bar chart
                 Row(
                   children: [
                     Text(getHumidityDescription(data.humidity.toDouble()), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                   ],
                 ),
                 const SizedBox(height: 16),
              ],
            ),

            // 降雨機率
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: [
                     Icon(Icons.umbrella_outlined, color: Colors.grey),
                     const SizedBox(width: 8), // Added SizedBox for consistent spacing
                     Text('降雨機率', style: Theme.of(context).textTheme.titleMedium),
                   ],
                 ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: data.precipitationChance.toDouble(),
                        maxValue: 100.0, // Max probability is 100%
                        colorStops: precipitationColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${data.precipitationChance}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                 const SizedBox(height: 4), // Added space below the bar chart
                 Row(
                   children: [
                      Text(getPrecipitationDescription(data.precipitationChance.toDouble()), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
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