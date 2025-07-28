import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class NotificationSettingsRepository {
  // --- Keys and Task Names ---
  static const _weatherAlertsEnabledKey = 'weatherAlertsEnabled';
  static const _weatherAlertsTaskId = 'weather_alert_task_id';
  static const _weatherAlertsTaskName = 'weatherAlertTask';

  static const _eveningForecastEnabledKey = 'eveningForecastEnabled';
  static const _eveningForecastTaskId = 'evening_forecast_task_id';
  static const _eveningForecastTaskName = 'eveningWeatherForecastTask';

  static const _imminentRainEnabledKey = 'imminentRainEnabled';
  static const _imminentRainTaskId = 'imminent_rain_task_id';
  static const _imminentRainTaskName = 'imminentRainTask';

  // A helper to check if we are on a platform that supports Workmanager
  bool get _isMobilePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // --- Weather Alerts ---

  Future<bool> isWeatherAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_weatherAlertsEnabledKey) ?? false;
  }

  Future<void> updateWeatherAlertsSetting(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weatherAlertsEnabledKey, isEnabled);

    if (_isMobilePlatform) {
      if (isEnabled) {
        await Workmanager().registerPeriodicTask(
          _weatherAlertsTaskId,
          _weatherAlertsTaskName,
          frequency: const Duration(hours: 4),
          constraints: Constraints(networkType: NetworkType.connected),
        );
        log("Weather alert task registered.", name: "NotificationSettingsRepo");
      } else {
        await Workmanager().cancelByUniqueName(_weatherAlertsTaskId);
        log("Weather alert task canceled.", name: "NotificationSettingsRepo");
      }
    }
  }

  // --- Evening Forecast ---

  Future<bool> isEveningForecastEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_eveningForecastEnabledKey) ?? false;
  }

  Future<void> updateEveningForecastSetting(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eveningForecastEnabledKey, isEnabled);

    if (_isMobilePlatform) {
      if (isEnabled) {
        await Workmanager().registerPeriodicTask(
          _eveningForecastTaskId,
          _eveningForecastTaskName,
          frequency: const Duration(days: 1),
          constraints: Constraints(networkType: NetworkType.connected),
        );
        log("Evening forecast task registered.", name: "NotificationSettingsRepo");
      } else {
        await Workmanager().cancelByUniqueName(_eveningForecastTaskId);
        log("Evening forecast task canceled.", name: "NotificationSettingsRepo");
      }
    }
  }

  // --- Imminent Rain ---

  Future<bool> isImminentRainEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_imminentRainEnabledKey) ?? false;
  }

  Future<void> updateImminentRainSetting(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_imminentRainEnabledKey, isEnabled);

    if (_isMobilePlatform) {
      if (isEnabled) {
        await Workmanager().registerPeriodicTask(
          _imminentRainTaskId,
          _imminentRainTaskName,
          frequency: const Duration(minutes: 30),
          constraints: Constraints(networkType: NetworkType.connected),
        );
        log("Imminent rain task registered.", name: "NotificationSettingsRepo");
      } else {
        await Workmanager().cancelByUniqueName(_imminentRainTaskId);
        log("Imminent rain task canceled.", name: "NotificationSettingsRepo");
      }
    }
  }
}
