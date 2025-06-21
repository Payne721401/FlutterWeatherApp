import 'package:flutter/material.dart';

class HorizontalBarChart extends StatelessWidget {
  final double value; // Current value (e.g., index level)
  final double maxValue; // Maximum possible value for the index
  final Color barColor;
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const HorizontalBarChart({
    super.key,
    required this.value,
    required this.maxValue,
    required this.barColor,
    this.height = 8.0,
    this.width = 50.0, // Small fixed width for indices
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
  });

  @override
  Widget build(BuildContext context) {
    // Ensure value is within bounds [0, maxValue]
    final clampedValue = value.clamp(0.0, maxValue);
    final fillWidth = (clampedValue / maxValue) * width;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300], // Background of the bar
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          Container(
            width: fillWidth,
            height: height,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: borderRadius,
            ),
          ),
        ],
      ),
    );
  }
}
