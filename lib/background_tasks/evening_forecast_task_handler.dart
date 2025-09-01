import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/services/notification_service.dart';
import 'package:weatherpro/services/firestore_service.dart';
import 'package:weatherpro/services/location_service.dart';
import 'package:weatherpro/features/weather/domain/repositories/weather_forecast_repository.dart';
import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';
import 'package:weatherpro/features/weather/data/models/ui_weather_forecast.dart';

class EveningForecastTaskHandler {
  // --- START OF MODIFICATION ---
  final NotificationService notificationService;
  final LocationService locationService;
  final WeatherForecastRepository weatherRepo;
  final SharedPreferences? prefsForTesting;

  EveningForecastTaskHandler()
      : notificationService = NotificationService(),
        locationService = LocationService(),
        weatherRepo = WeatherForecastRepositoryImpl(FirestoreService()),
        prefsForTesting = null;

  @visibleForTesting
  EveningForecastTaskHandler.testable({
    required this.notificationService,
    required this.locationService,
    required this.weatherRepo,
    required this.prefsForTesting,
  });
  // --- END OF MODIFICATION ---

  Future<bool> execute() async {
    const String logName = 'EveningForecastTask';

    final prefs = prefsForTesting ?? await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey) ?? false;

    if (!isEnabled) {
      dev.log("Task skipped: Evening forecast is disabled by the user.", name: logName);
      return true;
    }

    await notificationService.init();

    try {
      final position = await locationService.getCurrentLocation();
      final adminDivision = await locationService.getAdministrativeDivision(
          position.latitude, position.longitude);

      if (adminDivision == null) {
        dev.log("Could not determine administrative division for current location.", name: logName);
        return true;
      }

      final locationId = adminDivision.replaceAll(' ', '_');
      final weatherData = await weatherRepo.getForecastData(locationId);

      if (weatherData == null || weatherData.dailyForecasts.isEmpty) {
        dev.log("No forecast data available for $adminDivision.", name: logName);
        return true;
      }
      
      final now = DateTime.now();
      final tomorrow = DateUtils.dateOnly(now.add(const Duration(days: 1)));
      final tomorrowsForecasts = weatherData.dailyForecasts
          .where((f) => DateUtils.isSameDay(f.date, tomorrow))
          .toList();

      if (tomorrowsForecasts.isEmpty) {
        dev.log("No forecast entries found for tomorrow in $adminDivision.", name: logName);
        return true;
      }

      final double highTemp = tomorrowsForecasts
          .map((f) => f.dayTempHigh)
          .reduce(max);
      
      final double lowTemp = tomorrowsForecasts
          .map((f) => f.dayTempLow)
          .reduce(min);
      
      final String weatherCondition = tomorrowsForecasts.first.dayName == '明天' 
                                      ? weatherData.condition ?? '未知' 
                                      : '未知';

      final String title = '明日天氣預報 - $adminDivision';
      final String body =
          '明日: ${lowTemp.round()}° - ${highTemp.round()}°C，天氣狀況 ${weatherCondition}。';

      await notificationService.showNotification(
          id: NotificationIds.eveningWeatherForecast,
          title: title,
          body: body,
          payload: 'evening_forecast_payload');

      dev.log("Evening forecast notification sent for current location: $adminDivision.", name: logName);
      
      return true;
    } catch (e) {
      dev.log("Error executing evening forecast task: $e", name: logName);
      return false;
    }
  }
}
