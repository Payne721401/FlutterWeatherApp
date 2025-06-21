import 'package:flutter/material.dart';

// Define a class to hold color stop information
class ColorStop {
  final double stop;
  final Color color;

  ColorStop(this.stop, this.color);
}

class ParameterBarChart extends StatelessWidget {
  final double value;
  final double maxValue;
  final List<ColorStop> colorStops;
  final double height;
  final double width;

  const ParameterBarChart({
    Key? key,
    required this.value,
    required this.maxValue,
    required this.colorStops,
    this.height = 8.0,
    this.width = double.infinity, // Default to full width
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure value is within the range [0, maxValue]
    final clampedValue = value.clamp(0.0, maxValue);
    final percentage = clampedValue / maxValue;

    // Find the appropriate color based on value and color stops
    Color barColor = colorStops.isNotEmpty ? colorStops.first.color : Colors.grey; // Default to first color stop or grey
    for (int i = 0; i < colorStops.length; i++) {
      if (value <= colorStops[i].stop) {
        barColor = colorStops[i].color;
        break;
      } else if (i < colorStops.length - 1 && value < colorStops[i + 1].stop) {
         // If value is between two stops, use the color of the lower stop
         barColor = colorStops[i].color;
         break;
      }
    }
     // Handle case where value is greater than the last stop
     if (colorStops.isNotEmpty && value > colorStops.last.stop) {
       barColor = colorStops.last.color;
     }

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias, // Clip the progress bar to its rounded corners
      decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(height / 2), // Apply rounded corners
      ),
      child: LinearProgressIndicator(
        value: percentage, // Use percentage for the progress
        backgroundColor: Colors.grey[300], // Background of the bar
        valueColor: AlwaysStoppedAnimation<Color>(
          barColor, // Use the determined color
        ),
      ),
    );
  }
}
