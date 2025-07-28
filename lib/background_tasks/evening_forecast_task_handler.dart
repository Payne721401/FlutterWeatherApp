import 'dart:developer' as dev; // Use a prefix to avoid ambiguity
import 'dart:math'; // For min/max
import 'package:flutter/material.dart'; // For DateUtils
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/features/weather/domain/repositories/weather_forecast_repository.dart';
import 'package:myapp/features/weather/data/models/ui_weather_forecast.dart';

class EveningForecastTaskHandler {
  Future<bool> execute() async {
    const String logName = 'EveningForecastTask';
    final notificationService = NotificationService();
    await notificationService.init();

    // 1. Instantiate the services needed to get current location and weather data.
    final locationService = LocationService();
    final weatherRepo = WeatherForecastRepositoryImpl(FirestoreService());

    try {
      // 2. Get the user's current physical location.
      final position = await locationService.getCurrentLocation();
      final adminDivision = await locationService.getAdministrativeDivision(
          position.latitude, position.longitude);

      if (adminDivision == null) {
        dev.log("Could not determine administrative division for current location.", name: logName);
        return true; // Nothing to do, but task is successful.
      }

      // 3. Fetch weather data for the determined location.
      final locationId = adminDivision.replaceAll(' ', '_');
      final weatherData = await weatherRepo.getForecastData(locationId);

      if (weatherData == null || weatherData.dailyForecasts.isEmpty) {
        dev.log("No forecast data available for $adminDivision.", name: logName);
        return true;
      }
      
      // 4. Find all forecast entries for "tomorrow".
      final now = DateTime.now();
      final tomorrow = DateUtils.dateOnly(now.add(const Duration(days: 1)));
      final tomorrowsForecasts = weatherData.dailyForecasts
          .where((f) => DateUtils.isSameDay(f.date, tomorrow))
          .toList();

      if (tomorrowsForecasts.isEmpty) {
        dev.log("No forecast entries found for tomorrow in $adminDivision.", name: logName);
        return true;
      }

      // 5. Aggregate the data for a full-day summary.
      final double highTemp = tomorrowsForecasts
          .map((f) => f.dayTempHigh)
          .reduce(max);
      
      final double lowTemp = tomorrowsForecasts
          .map((f) => f.dayTempLow)
          .reduce(min);
      
      final String weatherCondition = tomorrowsForecasts.first.dayName == '明天' 
                                      ? weatherData.condition ?? '未知' 
                                      : '未知';

      // 6. Build and send the notification.
      final String title = '明日天氣預報 - $adminDivision';
      final String body =
          '明日: ${lowTemp.round()}° - ${highTemp.round()}°C，天氣狀況 ${weatherCondition}。';

      await notificationService.showNotification(
          id: NotificationIds.eveningWeatherForecast,
          title: title,
          body: body,
          payload: 'evening_forecast_payload');

      dev.log("Evening forecast notification sent for current location: $adminDivision.", name: logName);
      
      return true; // Task succeeded
    } catch (e) {
      dev.log("Error executing evening forecast task: $e", name: logName);
      return false; // Task failed
    }
  }
}
