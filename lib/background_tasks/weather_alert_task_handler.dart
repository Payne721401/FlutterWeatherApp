import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/features/weather/data/services/alert_service.dart';
import 'package:myapp/features/weather/domain/repositories/alert_repository.dart';
import 'package:myapp/features/weather/data/models/weather_alert.dart';

class WeatherAlertTaskHandler {
  Future<bool> execute() async {
    const String logName = 'WeatherAlertTask';
    final notificationService = NotificationService();
    await notificationService.init();

    final alertRepo = AlertRepositoryImpl(AlertService());

    try {
      final List<WeatherAlert> alerts = await alertRepo.fetchAlerts();
      if (alerts.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? lastNotifiedAlertTitle = prefs.getString('lastNotifiedAlertTitle');
        final WeatherAlert latestAlert = alerts.first;

        if (latestAlert.title != lastNotifiedAlertTitle) {
          log("New weather alert found: ${latestAlert.title}", name: logName);
          await notificationService.showNotification(
            id: NotificationIds.weatherAlert,
            title: '天氣特報：${latestAlert.title}',
            body: latestAlert.description,
            payload: 'weather_alert_payload',
          );
          await prefs.setString('lastNotifiedAlertTitle', latestAlert.title);
        } else {
          log("No new alerts since last check.", name: logName);
        }
      } else {
        log("No active alerts found.", name: logName);
      }
      return true; // Task succeeded
    } catch (e) {
      log("Error executing weather alert task: $e", name: logName);
      return false; // Task failed
    }
  }
}
