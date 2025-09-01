import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/services/notification_service.dart';
import 'package:weatherpro/features/weather/data/services/alert_service.dart';
import 'package:weatherpro/features/weather/domain/repositories/alert_repository.dart';
import 'package:weatherpro/features/weather/data/models/weather_alert.dart';
import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';

class WeatherAlertTaskHandler {
  final NotificationService notificationService;
  final AlertRepository alertRepo;
  final SharedPreferences? prefsForTesting;

  WeatherAlertTaskHandler()
      : notificationService = NotificationService(),
        alertRepo = AlertRepositoryImpl(AlertService()),
        prefsForTesting = null;

  @visibleForTesting
  WeatherAlertTaskHandler.testable({
    required this.notificationService,
    required this.alertRepo,
    required this.prefsForTesting,
  });

  Future<bool> execute() async {
    const String logName = 'WeatherAlertTask';

    final prefs = prefsForTesting ?? await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool(NotificationSettingsRepository.weatherAlertsEnabledKey) ?? false;

    if (!isEnabled) {
      log("Task skipped: Weather alerts are disabled by the user.", name: logName);
      return true;
    }

    await notificationService.init();

    try {
      final List<WeatherAlert> alerts = await alertRepo.fetchAlerts();
      if (alerts.isNotEmpty) {
        // --- MODIFICATION START ---
        // 1. Define the new key for storing the timestamp.
        const String lastNotifiedAlertTimestampKey = 'lastNotifiedAlertTimestamp';
        
        // 2. Read the stored timestamp (as an integer), defaulting to 0 if not found.
        final int lastNotifiedAlertTimestamp = prefs.getInt(lastNotifiedAlertTimestampKey) ?? 0;
        
        final WeatherAlert latestAlert = alerts.first;
        final int latestAlertTimestamp = latestAlert.issuedTime.millisecondsSinceEpoch;

        // 3. Compare the timestamp of the new alert with the stored timestamp.
        if (latestAlertTimestamp > lastNotifiedAlertTimestamp) {
          log("New weather alert found (Timestamp: $latestAlertTimestamp): ${latestAlert.title}", name: logName);
          await notificationService.showNotification(
            id: NotificationIds.weatherAlert,
            title: '天氣特報：${latestAlert.title}',
            body: latestAlert.description,
            payload: 'weather_alert_payload',
          );
          // 4. Save the new timestamp to SharedPreferences.
          await prefs.setInt(lastNotifiedAlertTimestampKey, latestAlertTimestamp);
        } else {
          log("No new alerts since last check (Timestamp: $lastNotifiedAlertTimestamp).", name: logName);
        }
        // --- MODIFICATION END ---
      } else {
        log("No active alerts found.", name: logName);
      }
      return true;
    } catch (e) {
      log("Error executing weather alert task: $e", name: logName);
      return false;
    }
  }
}
