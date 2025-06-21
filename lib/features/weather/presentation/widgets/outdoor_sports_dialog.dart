import 'package:flutter/material.dart';
import '../../data/models/weather_data.dart';
import 'parameter_bar_chart.dart';
import '../utils/exercise_advice_utils.dart'; // Import the new utility file

class OutdoorSportsDialog extends StatelessWidget {
  const OutdoorSportsDialog({super.key, required this.data});

  final WeatherInfo data;

  @override
  Widget build(BuildContext context) {
    // Define color stops for outdoor sports parameters with vivid colors
    final feelsLikeColors = [
      ColorStop(10.0, Colors.red), // <10 too cold
      ColorStop(15.0, Colors.orange), // 10-15 cold (caution)
      ColorStop(20.0, Colors.yellow), // 15-20 cool (attention)
      ColorStop(30.0, Colors.green), // 20-30 comfortable/good
      ColorStop(34.0, Colors.orange), // 30-34 warm (attention)
      ColorStop(double.infinity, Colors.red), // >34 hot (too hot)
    ];
    final windSpeedColors = [
      ColorStop(2.0, Colors.green), // <2 good
      ColorStop(4.0, Colors.yellow), // 2-4 moderate
      ColorStop(6.0, Colors.orange), // 4-6 strong
      ColorStop(double.infinity, Colors.red), // >6 very strong
    ];
    final aqiColors = [
      ColorStop(50.0, Colors.green), // 0-50 good
      ColorStop(100.0, Colors.yellow), // 51-100 moderate
      ColorStop(150.0, Colors.orange), // 101-150 unhealthy for sensitive groups
      ColorStop(double.infinity, Colors.red), // >150 unhealthy/hazardous
    ];
    final precipitationColors = [
      ColorStop(10.0, Colors.green), // <10 green (very low chance)
      ColorStop(30.0, Colors.yellow), // 10-30 yellow (low to moderate chance)
      ColorStop(50.0, Colors.orange), // 30-50 orange (moderate chance)
      ColorStop(double.infinity, Colors.red), // >50 red (high chance)
    ];
    final uvIndexColors = [
      ColorStop(2.0, Colors.green), // 0-2 low
      ColorStop(5.0, Colors.yellow), // 3-5 moderate
      ColorStop(7.0, Colors.orange), // 6-7 high
      ColorStop(double.infinity, Colors.red), // >7 very high/extreme
    ];

    // Calculate exercise advice based on the new logic
    final exerciseSuggestion = getExerciseSuggestion(
      temp: data.feelsLike.toDouble(), // Using feelsLike for temperature for consistency
      windLevel: data.windSpeed.toDouble(),
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
          color: getBackgroundColorForExercise(exerciseIndexValue), // Set title background color based on exercise index
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withAlpha((255 * 0.1).round()),
              child: Icon(
                Icons.directions_run,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '戶外運動',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ), // Title text color black
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exerciseSuggestion, // Display exercise suggestion here
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ), // Stronger style
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
                    Icon(Icons.thermostat_outlined, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      '體感溫度',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: data.feelsLike.toDouble(),
                        maxValue:
                            40.0, // Assuming max felt temperature for chart scale
                        colorStops: feelsLikeColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.feelsLike}°C',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Added space below the bar chart
                Row(
                  children: [
                    Text(
                      getTemperatureForExerciseDescription(data.feelsLike.toDouble()),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

            // 風速
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wind_power, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text('風速', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: data.windSpeed.toDouble(),
                        maxValue:
                            7.0, // Adjusted max wind speed for chart scale based on exercise advice logic
                        colorStops: windSpeedColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.windSpeed} 級',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Added space below the bar chart
                Row(
                  children: [
                    Text(
                      getWindLevelDescription(data.windSpeed.toDouble()),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

            // 空氣品質(AQI)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.air, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      '空氣品質(AQI)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: data.aqi.toDouble(),
                        maxValue: 200.0, // Assuming max AQI for chart scale
                        colorStops: aqiColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.aqi}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Added space below the bar chart
                Row(
                  children: [
                    Text(
                      getAQIDescription(data.aqi),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
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
                    const SizedBox(width: 8),
                    Text(
                      '降雨機率',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value: data.precipitationChance.toDouble(),
                        maxValue: 100.0,
                        colorStops: precipitationColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.precipitationChance}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Added space below the bar chart
                Row(
                  children: [
                    Text(
                      getPrecipitationDescription(
                        data.precipitationChance.toDouble(),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

            // 紫外線
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('紫外線', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ParameterBarChart(
                        value:
                            data.uvIndex.toDouble(), // Assuming uvIndex is double/int
                        maxValue: 11.0, // Max UV index for chart scale
                        colorStops: uvIndexColors,
                        height: 10.0,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.uvIndex}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Added space below the bar chart
                Row(
                  children: [
                    Text(
                      getUVIndexDescription(data.uvIndex),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
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
