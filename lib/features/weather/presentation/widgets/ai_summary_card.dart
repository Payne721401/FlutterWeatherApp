import 'package:flutter/material.dart';
import 'weather_card.dart';
// MODIFICATION: Removed dependency on weather_data.dart
// import '../../data/models/weather_data.dart';

class AiSummaryCard extends StatelessWidget {
  // MODIFICATION: Changed to directly receive aiSummary as a nullable String
  final String? aiSummary;

  const AiSummaryCard({super.key, this.aiSummary});

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
                  // MODIFICATION: Use the directly passed aiSummary, with a fallback text
                  aiSummary ?? '這裡將顯示來自 AI 助手的摘要。請輸入提示以獲取天氣分析。', 
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
