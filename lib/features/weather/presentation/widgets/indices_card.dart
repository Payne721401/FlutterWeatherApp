import 'package:flutter/material.dart';
import '../../data/models/weather_data.dart';
import 'weather_card.dart';
import 'horizontal_bar_chart.dart';
import 'clothing_advice_dialog.dart'; // Import clothing advice dialog
import 'drying_index_dialog.dart'; // Import drying index dialog
import 'outdoor_sports_dialog.dart'; // Import outdoor sports dialog
import '../utils/clothing_advice_utils.dart'; // Import the new clothing utility file
import '../utils/drying_advice_utils.dart'; // Import the new drying utility file
import '../utils/exercise_advice_utils.dart'; // Import the new exercise utility file

class IndicesCard extends StatelessWidget {
  final WeatherInfo data;

  const IndicesCard({super.key, required this.data});

  // Helper for Advice Items
  Widget _buildAdviceItem(BuildContext context, IconData icon, String title, String advice, int value, int maxValue, VoidCallback onTap) {
    // Determine color for the small bar based on suitability (green to red gradient concept)
     final suitabilityColors = [Colors.green, Colors.greenAccent, Colors.yellow, Colors.orange, Colors.red];
     final percentage = value / maxValue;
     Color itemBarColor = _getColorForSuitability(percentage, suitabilityColors);

    return Expanded( // Use Expanded to distribute space evenly
      child: InkWell( // Make the item tappable
        onTap: onTap, // Call the provided onTap function
        borderRadius: BorderRadius.circular(10.0), // Add a subtle ripple effect
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Add some padding for better tapping area
          child: Column(
            children: [
              CircleAvatar( // Circle background for icon
                radius: 22,
                backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                child: Icon(icon, size: 24, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]), textAlign: TextAlign.center), // Center align title
              const SizedBox(height: 2),
              Text(advice, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center), // Center align advice
              const SizedBox(height: 4), // Space between advice text and chart
              HorizontalBarChart(
                value: value.toDouble(),
                maxValue: maxValue.toDouble(),
                barColor: itemBarColor, // Use the calculated suitability color
                width: 60, // Adjust width as needed
              ),
               Text(
                 '($value/$maxValue)', // Display numerical value
                 style: TextStyle(fontSize: 10, color: Colors.grey[600])
               ), // Display numerical value
            ],
          ),
        ),
      ),
    );
  }

   // Helper to get color based on suitability percentage (green to red)
   Color _getColorForSuitability(double percentage, List<Color> colors) {
     if (percentage <= 0.0) return colors.first;
     if (percentage >= 1.0) return colors.last;

     final section = 1.0 / (colors.length - 1);
     int startIndex = (percentage / section).floor();
     int endIndex = (percentage / section).ceil();

     startIndex = startIndex.clamp(0, colors.length - 1);
     endIndex = endIndex.clamp(0, colors.length - 1);

     if (startIndex == endIndex) {
       return colors[startIndex];
     }

     final sectionPercentage = (percentage - startIndex * section) / section;

     return Color.lerp(colors[startIndex], colors[endIndex], sectionPercentage)!;
   }


  @override
  Widget build(BuildContext context) {
    // Assuming max values for indices are 5 (adjust as needed)
    const int maxIndexValue = 5;

    // Calculate clothing advice based on the new logic
    final tempDifference = (data.tempHigh - data.tempLow).abs();
    final outfitSuggestion = generateOutfitSuggestion(data.feelsLike.toDouble(), tempDifference.toDouble());
    final clothingIndexValue = getClothingIndexValue(outfitSuggestion);

    // Calculate drying advice based on the new logic
    final dryingSuggestion = getDryingSuggestion(
      temp: data.temperature.toDouble(),
      humidity: data.humidity.toDouble(),
      rainProb: data.precipitationChance.toDouble(),
    );
    final dryingIndexValue = getDryingIndexValue(dryingSuggestion);

    // Calculate exercise advice based on the new logic
    final exerciseSuggestion = getExerciseSuggestion(
      temp: data.feelsLike.toDouble(),
      windLevel: data.windSpeed.toDouble(),
      aqi: data.aqi,
      rainProb: data.precipitationChance.toDouble(),
      uvIndex: data.uvIndex,
    );
    final exerciseIndexValue = getExerciseIndexValue(exerciseSuggestion);

    return WeatherCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Advice Row with numerical values and charts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start, // Align items at the top
            children: [
              _buildAdviceItem(
                context,
                Icons.checkroom,
                '穿搭建議',
                outfitSuggestion, // Display the outfit suggestion directly
                clothingIndexValue, // Use the new clothing index value
                maxIndexValue,
                 () {
                   showDialog(
                     context: context,
                     builder: (BuildContext context) {
                       return ClothingAdviceDialog(data: data);
                     },
                   );
                 },
              ),
              _buildAdviceItem(
                context,
                Icons.wb_sunny_outlined,
                '曬衣建議',
                dryingSuggestion, // Use the new drying suggestion
                dryingIndexValue, // Use the new drying index value
                maxIndexValue,
                 () {
                   showDialog(
                     context: context,
                     builder: (BuildContext context) {
                       return DryingIndexDialog(data: data);
                     },
                   );
                 },
              ),
              _buildAdviceItem(
                context,
                Icons.directions_run,
                '戶外運動',
                exerciseSuggestion, // Use the new exercise suggestion
                exerciseIndexValue, // Use the new exercise index value
                maxIndexValue,
                 () {
                   showDialog(
                     context: context,
                     builder: (BuildContext context) {
                       return OutdoorSportsDialog(data: data);
                     },
                   );
                 },
              ),
            ]
          ),
          // Removed Placeholder for Directional Bar Chart
        ],
      )
    );
  }
}