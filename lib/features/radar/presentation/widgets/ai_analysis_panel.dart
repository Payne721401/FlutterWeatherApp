import 'package:flutter/material.dart';

class AiAnalysisPanel extends StatelessWidget {
  // Add the onClose callback parameter
  final VoidCallback onClose;

  // Update the constructor to require onClose
  const AiAnalysisPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero, // Use padding from the parent (RadarView)
      elevation: 2,
      color: const Color(0xFFf0f7ff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blueAccent.shade100, width: 1) // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column( // Use Column to easily add title row
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- START: Added Title Row with Close Button ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row( // Group icon and title
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 18), // Updated Icon
                    const SizedBox(width: 8),
                    Text(
                      'AI雷達分析',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), // Use theme
                    ),
                  ],
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // Remove default padding
                  tooltip: "關閉分析",
                  onPressed: onClose, // Call the provided callback
                  color: Colors.grey[600], // Adjust color as needed
                )
              ],
            ),
            // --- END: Added Title Row with Close Button ---
            const SizedBox(height: 8), // Spacer between title and content
            // Placeholder text (Content)
            const Text(
              '西南方有一道雨帶正在向台北市移動，預計40-50分鐘後抵達。建議提前規劃行程，雨勢將持續約2小時，降雨強度為中至大雨。',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
