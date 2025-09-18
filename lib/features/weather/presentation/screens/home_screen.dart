import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/weather_data_state.dart';

import '../widgets/search_bar_widget.dart';
import '../widgets/indices_card.dart';
import '../widgets/hourly_forecast_card.dart';
import '../widgets/weekly_forecast_card.dart';
import '../widgets/combined_temperature_forecast_card.dart';
import '../widgets/observation_card.dart';
import '../../../../widgets/native_ad_widget.dart';

// --- MODIFICATION START: Import versioning and dialog services ---
import '../../../../services/app_version_service.dart';
import '../../../../widgets/app_dialogs.dart';
// --- MODIFICATION END ---

// --- MODIFICATION START: Converted to StatefulWidget ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Show the beta warning dialog on the first launch, after the screen is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowBetaWarning();
    });
  }

  void _checkAndShowBetaWarning() async {
    if (!mounted) return;
    final appVersionService = context.read<AppVersionService>();

    if (appVersionService.isFirstLaunch()) {
      // The `await` ensures that we only mark it as seen after the user
      // has dismissed the dialog.
      await showBetaWarningDialog(context);
      await appVersionService.markBetaWarningAsSeen();
    }
  }
  // --- MODIFICATION END ---

  @override
  Widget build(BuildContext context) {
    final weatherDataState = context.watch<WeatherDataState>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
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
          : weatherDataState.error != null
              ? Center(key: const ValueKey('error'), child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    weatherDataState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16)
                  ),
                ))
              : (weatherDataState.temperature != null
                  ? _buildWeatherDetails(context, weatherDataState)
                  : const Center(key: ValueKey('prompt'), child: Text('點擊上方查詢地點', style: TextStyle(color: Colors.grey, fontSize: 16)))),
    );
  }

  Widget _buildWeatherDetails(BuildContext context, WeatherDataState newState) {
    return ListView(
      key: ValueKey('weather_details_${newState.currentLocationName}'),
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
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
          isDaytime: newState.isDaytime,
        ),
        const SizedBox(height: 6),
        const SmallNativeAd(),
        const SizedBox(height: 6),
        IndicesCard(
          temperature: newState.temperature,
          feelsLike: newState.hourlyForecasts.isNotEmpty ? newState.hourlyForecasts.first.apparentTemperature : null,
          tempHigh: newState.tempHigh,
          tempLow: newState.tempLow,
          humidity: newState.dailyForecasts.isNotEmpty
              ? newState.dailyForecasts.first.humidity
              : null,
          precipitationChance: newState.dailyForecasts.isNotEmpty
              ? newState.dailyForecasts.first.dayPrecipitationChance
              : null,
          aqi: newState.airQuality?.aqi,
          uvIndex: newState.uvIndex?.uvIndex,
          windSpeed: newState.observation?.observations?.windSpeedAsDouble,
        ),
        const SizedBox(height: 12),
        ObservationCard(
          stationName: newState.observation?.stationName,
          windSpeed: newState.observation?.observations?.windSpeedAsDouble,
          windDirection: newState.observation?.observations?.windDirectionAsDouble,
          humidity: newState.observation?.observations?.humidityAsInt,
          precipitation: newState.observation?.observations?.precipitationAsDouble,
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
