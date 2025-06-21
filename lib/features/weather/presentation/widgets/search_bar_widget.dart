import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Assuming Provider is used
import '../state/weather_state.dart';
import '../../data/models/weather_data.dart'; // For WeatherAlert
import 'package:intl/intl.dart'; // For DateFormat

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherState = context.watch<WeatherState>();
    final alerts = weatherState.alerts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Material(
              elevation: 1.0, // Subtle elevation
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.white, // White background for search bar
              child: TextField(
                controller: weatherState.searchController,
                onChanged: weatherState.updateSuggestions,
                onSubmitted: (value) {
                  if (weatherState.suggestions.isNotEmpty) {
                    weatherState.handleSuggestionTap(weatherState.suggestions.first, context);
                  } else if (value.isNotEmpty) {
                    weatherState.handleSuggestionTap(value, context);
                  }
                },
                decoration: InputDecoration(
                  hintText: '查詢地點...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent, // Handled by Material widget
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Alert Icon with Badge - Conditionally display if alerts exist
          if (alerts.isNotEmpty)
            Stack(
              clipBehavior: Clip.none, // Allow the badge to overflow the Stack boundaries
              children: [
                IconButton(
                  icon: Icon(Icons.warning_amber_rounded, size: 28, color: Theme.of(context).colorScheme.error),
                  tooltip: '警特報',
                  onPressed: () => _showWeatherAlerts(context, alerts),
                ),
                Positioned(
                  right: 0, // Position the badge at the top right of the icon
                  top: -4, // Adjust the vertical position
                  child: Container(
                    padding: const EdgeInsets.all(4), // Padding inside the badge
                    decoration: BoxDecoration(
                      color: Colors.red, // Red background for the badge
                      borderRadius: BorderRadius.circular(10), // Make it circular
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16, // Minimum width for single digit
                      minHeight: 16, // Minimum height
                    ),
                    child: Text(
                      alerts.length.toString(), // Display the number of alerts
                      style: const TextStyle(
                        color: Colors.white, // White text
                        fontSize: 10, // Smaller font size
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            )
          else
            const SizedBox(width: 48), // Placeholder to maintain alignment if no alerts
        ],
      ),
    );
  }

  void _showWeatherAlerts(BuildContext context, List<WeatherAlert> alerts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 10),
            const Text('警特報'), // Dialog title remains generic
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: alerts.isEmpty
              ? const Text('目前無警特報')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    // Format the issued time without the year
                    final formattedTime = DateFormat('M/dd HH:mm').format(alert.issuedTime);
                    // Combine title and formatted time
                    final String titleText = "${alert.title} (發布時間 $formattedTime)";

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        titleText, // Use the combined title and time
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                      subtitle: Text(alert.description), // Only display description in subtitle
                      isThreeLine: true, // Allow more space for description
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}
