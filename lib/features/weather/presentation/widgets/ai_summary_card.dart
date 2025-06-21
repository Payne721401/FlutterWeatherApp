import 'package:flutter/material.dart';
import '../../data/models/weather_data.dart';
import 'weather_card.dart';

class AiSummaryCard extends StatelessWidget {
  final WeatherInfo data;

  const AiSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return WeatherCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_sync, color: Theme.of(context).primaryColor, size: 24), // AI Icon
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI 天氣小幫手", // Title
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  data.aiSummary, // AI Text
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
