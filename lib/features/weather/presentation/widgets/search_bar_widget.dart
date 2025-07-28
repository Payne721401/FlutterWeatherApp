import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../state/weather_data_state.dart';
import '../../data/models/weather_alert.dart';
import '../../../location/presentation/screens/manage_saved_locations_screen.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherDataState = context.watch<WeatherDataState>();
    final alerts = weatherDataState.alerts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      // MODIFICATION: Use a Stack to handle true centering while accommodating the right-aligned icon.
      child: SizedBox(
        height: 48, // Give the Stack a defined height for vertical alignment.
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: The centered, clickable location text and icon.
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageSavedLocationsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Important: This makes the row only as wide as its children.
                    children: [
                      Icon(Icons.search, size: 28.0, color: Colors.black87),
                      const SizedBox(width: 8.0),
                      Flexible( // Use Flexible to prevent long text from causing overflow.
                        child: Text(
                          weatherDataState.currentLocationName ?? '查找或管理地點...',
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Layer 2: The alert icon, aligned to the far right of the Stack.
            Align(
              alignment: Alignment.centerRight,
              child: (alerts.isNotEmpty)
                  ? Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.warning_amber_rounded, size: 28, color: Theme.of(context).colorScheme.error),
                          tooltip: '警特報',
                          onPressed: () => _showWeatherAlerts(context, alerts),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              alerts.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      ],
                    )
                  // Use a SizedBox with the same width as the IconButton to maintain spacing.
                  : const SizedBox(width: 48), 
            ),
          ],
        ),
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
            const Text('警特報'),
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
                    final formattedTime = DateFormat('M/dd HH:mm').format(alert.issuedTime.toLocal());
                    final String titleText = "${alert.title} (發布時間 $formattedTime)";

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                      subtitle: Text(alert.description),
                      isThreeLine: true,
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
