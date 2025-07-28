import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// MODIFICATION: Cleaned up imports, no longer need LocationSearchState here.
import '../state/weather_data_state.dart';

// Import widgets
import '../widgets/search_bar_widget.dart';
import '../widgets/indices_card.dart';
import '../widgets/hourly_forecast_card.dart';
import '../widgets/weekly_forecast_card.dart';
import '../widgets/combined_temperature_forecast_card.dart';
import '../widgets/other_details_sunrise_sunset_card.dart';
import 'package:myapp/features/weather/presentation/widgets/banner_ad_widget.dart';
import 'package:myapp/features/weather/presentation/widgets/native_ad_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherDataState = context.watch<WeatherDataState>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        // MODIFICATION: GestureDetector is removed as it's no longer needed on this screen.
        child: Column(
          children: [
            const SearchBarWidget(),
            
            Expanded(
              child: _buildContentArea(context, weatherDataState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, WeatherDataState weatherDataState) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: weatherDataState.isLoading
          ? Center(key: const ValueKey('loading'), child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : (weatherDataState.temperature != null
              ? _buildWeatherDetails(context, weatherDataState)
              : const Center(key: ValueKey('prompt'), child: Text('點擊上方管理或查找地點', style: TextStyle(color: Colors.grey, fontSize: 16)))),
    );
  }

  Widget _buildWeatherDetails(BuildContext context, WeatherDataState newState) {
    return ListView(
      key: ValueKey('weather_details_${newState.currentLocationName}'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        CombinedTemperatureForecastCard(
          condition: newState.condition,
          conditionIcon: newState.conditionIcon,
          temperature: newState.temperature,
          feelsLike: newState.hourlyForecasts.isNotEmpty ? newState.hourlyForecasts.first.apparentTemperature : null,
          tempHigh: newState.tempHigh,
          tempLow: newState.tempLow,
          precipitationChance: newState.hourlyForecasts.isNotEmpty
              ? newState.hourlyForecasts.first.precipitationChance
              : null,
          aqi: newState.airQuality?.aqi,
          aqiLevel: newState.airQuality?.status,
        ),
        const SizedBox(height: 6),
        const SmallNativeAd(),
        //const BannerAdWidget(),
        const SizedBox(height: 6),
        
        IndicesCard(
          temperature: newState.temperature,
          feelsLike: newState.hourlyForecasts.isNotEmpty ? newState.hourlyForecasts.first.apparentTemperature : null,
          tempHigh: newState.tempHigh,
          tempLow: newState.tempLow,
          humidity: newState.observation?.observations?.humidityAsInt,
          precipitationChance: newState.hourlyForecasts.isNotEmpty
              ? newState.hourlyForecasts.first.precipitationChance
              : null,
          aqi: newState.airQuality?.aqi,
          uvIndex: newState.uvIndex?.uvIndex,
          windSpeed: newState.observation?.observations?.windSpeedAsDouble,
        ),
        const SizedBox(height: 12),

        OtherDetailsSunriseSunsetCard(
          windSpeed: newState.observation?.observations?.windSpeedAsDouble,
          humidity: newState.observation?.observations?.humidityAsInt,
          precipitationChance: newState.hourlyForecasts.isNotEmpty
              ? newState.hourlyForecasts.first.precipitationChance
              : null,
          uvIndex: newState.uvIndex?.uvIndex,
          uvLevel: newState.uvIndex?.level,
          aqi: newState.airQuality?.aqi,
          aqiLevel: newState.airQuality?.status,
          sunrise: newState.sunriseSunset?.sunriseTime,
          sunset: newState.sunriseSunset?.sunsetTime,
        ),
        const SizedBox(height: 12),
        
        HourlyForecastCard(hourlyForecasts: newState.hourlyForecasts),
        const SizedBox(height: 12),
        WeeklyForecastCard(dailyForecasts: newState.dailyForecasts),

        const SizedBox(height: 20),
      ],
    );
  }
}
