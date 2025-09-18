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

    // Find the appropriate color by iterating through the stops.
    // Default to the last color in the list, for values exceeding all stops.
    Color barColor = colorStops.last.color;
    for (final stop in colorStops) {
      // Find the first stop that the value is less than or equal to.
      if (value <= stop.stop) {
        barColor = stop.color;
        break;
      }
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
