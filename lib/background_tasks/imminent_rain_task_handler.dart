import 'dart:developer' as dev;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/services/notification_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/features/radar/data/models/rainfall_data.dart';
import 'package:myapp/features/radar/utils/rainfall_calculator.dart';
import 'package:myapp/utils/app_constants.dart'; // Import the new constants file

class ImminentRainTaskHandler {
  Future<bool> execute() async {
    const String logName = 'ImminentRainTask';
    final notificationService = NotificationService();
    await notificationService.init();

    try {
      final prefs = await SharedPreferences.getInstance();
      // Use the shared constant key to retrieve the URL
      final String? radarUrl = prefs.getString(radarRainfallUrlKey);

      if (radarUrl == null || radarUrl.isEmpty) {
        dev.log("Radar URL not found in SharedPreferences. Task cannot run.", name: logName);
        return true;
      }
      
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      final adminDivision = await locationService.getAdministrativeDivision(
          position.latitude, position.longitude);

      if (adminDivision == null) {
        dev.log("Could not determine administrative division.", name: logName);
        return true;
      }
      
      final response = await http.get(Uri.parse(radarUrl));
      if (response.statusCode != 200) {
        dev.log("Failed to fetch rainfall data. Status: ${response.statusCode}", name: logName);
        return false;
      }
      final rainfallData = RainfallData.fromJson(json.decode(utf8.decode(response.bodyBytes)));

      final rainfallLevel = RainfallCalculator.getLevelAt(
        data: rainfallData,
        userLat: position.latitude,
        userLon: position.longitude,
      );

      final int lastNotifiedLevel = prefs.getInt('lastNotifiedRainLevel') ?? RainfallLevel.noRain.index;

      if (rainfallLevel.index > RainfallLevel.noRain.index && rainfallLevel.index != lastNotifiedLevel) {
        final message = RainfallCalculator.getForecastMessageFromLevel(rainfallLevel, adminDivision);
        
        await notificationService.showNotification(
          id: NotificationIds.imminentRain,
          title: '即時降雨提醒',
          body: message,
          payload: 'imminent_rain_payload',
        );

        await prefs.setInt('lastNotifiedRainLevel', rainfallLevel.index);
        dev.log("Imminent rain notification sent. Level: $rainfallLevel", name: logName);

      } else {
        dev.log("No new significant rain or level unchanged. Current: $rainfallLevel, Last: ${RainfallLevel.values[lastNotifiedLevel]}", name: logName);
        if(rainfallLevel.index == RainfallLevel.noRain.index && lastNotifiedLevel != RainfallLevel.noRain.index) {
            await prefs.setInt('lastNotifiedRainLevel', RainfallLevel.noRain.index);
        }
      }
      
      return true;
    } catch (e) {
      dev.log("Error executing imminent rain task: $e", name: logName);
      return false;
    }
  }
}
