import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart'; // Import DateFormat
import '../../data/models/weather_data.dart';
import '../state/weather_state.dart';
// Import existing and new widgets
import '../widgets/search_bar_widget.dart';
import '../widgets/suggestions_list.dart';
import '../widgets/indices_card.dart'; // Keep this
// Removed unused import: import '../widgets/ai_summary_card.dart';
import '../widgets/hourly_forecast_card.dart'; // Keep this
import '../widgets/weekly_forecast_card.dart'; // Keep this

// Import the new independent widgets
import '../widgets/combined_temperature_forecast_card.dart';
import '../widgets/other_details_sunrise_sunset_card.dart';
import 'package:myapp/features/weather/presentation/widgets/banner_ad_widget.dart'; // <-- Changed to BannerAdWidget

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Hide keyboard on tap outside
            Provider.of<WeatherState>(context, listen: false).clearSuggestions(); // Also clear suggestions
          },
          child: Column(
            children: [
              // The alert icon next to the search bar should handle the alert dialog.
              const SearchBarWidget(),
              const SuggestionsList(), // Handles its own visibility based on state
              // Added location and update time display
              Consumer<WeatherState>(
                builder: (context, weatherState, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjusted padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18.0, color: Colors.grey), // Location icon
                            const SizedBox(width: 4.0),
                            Text(
                              weatherState.currentLocation.isNotEmpty 
                                  ? weatherState.currentLocation 
                                  : '獲取地點資訊...', // Display current selected/searched location
                              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                        Text(
                          weatherState.currentWeatherInfo?.lastUpdated != null
                              ? '更新於 ${DateFormat('HH:mm').format(weatherState.currentWeatherInfo!.lastUpdated)}'
                              : '', // Display update time from weather info
                          style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: _buildContentArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    return Consumer<WeatherState>(
      builder: (context, weatherState, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          key: ValueKey(weatherState.isLoading || weatherState.currentWeatherInfo == null),
          child: weatherState.isLoading
              ? Center(key: const ValueKey('loading'), child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
              : (weatherState.currentWeatherInfo != null
                  ? _buildWeatherDetails(weatherState.currentWeatherInfo!)
                  : Center(key: const ValueKey('prompt'), child: Text('請搜尋地點以查看天氣', style: TextStyle(color: Colors.grey[600])))),
        );
      },
    );
  }

  // Main scrolling view for weather details - implementing the new layout
  Widget _buildWeatherDetails(WeatherInfo data) {
    return ListView(
      key: ValueKey('weather_details_${data.locationName}'), // Important for AnimatedSwitcher
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Added vertical padding
      children: [
        // 1. Combined Temperature, 3-hour Forecast, and Temperature Chart Card
        CombinedTemperatureForecastCard(data: data), // Use the new widget
        const BannerAdWidget(), // <-- Changed to BannerAdWidget here

        const SizedBox(height: 12), // Spacing between cards

        // 2. Lifestyle Indices Card (Reusing the existing IndicesCard structure)
        IndicesCard(data: data), // Keep the existing IndicesCard

        const SizedBox(height: 12), // Spacing between cards

        // 3. Other Details + Sunrise/Sunset Card
        OtherDetailsSunriseSunsetCard(data: data), // Use the new widget

        const SizedBox(height: 12), // Spacing between cards

        // Keep the other cards below the main three, as they were not specified for re-arrangement
        // AiSummaryCard(data: data), // You can uncomment and place this where needed
        // const SizedBox(height: 12),
        HourlyForecastCard(hourlyForecasts: data.hourlyForecasts), // Full hourly forecast
        const SizedBox(height: 12),
        WeeklyForecastCard(dailyForecasts: data.dailyForecasts),

        const SizedBox(height: 20), // Bottom padding
      ],
    );
  }
}
