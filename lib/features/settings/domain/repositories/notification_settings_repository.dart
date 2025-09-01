// PRESERVED: Your original imports are fully kept.
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:weatherpro/features/settings/domain/repositories/workmanager_wrapper.dart';

class NotificationSettingsRepository {
  final SharedPreferences? _prefsForTesting;
  final WorkmanagerWrapper? _workmanagerForTesting;
  // --- START OF MODIFICATION 1 of 2 ---
  // This will hold the platform override ONLY during tests. It remains null in production.
  final bool? _isMobilePlatformForTesting;
  // --- END OF MODIFICATION 1 of 2 ---

  // Production constructor remains unchanged.
  NotificationSettingsRepository()
      : _prefsForTesting = null,
        _workmanagerForTesting = null,
        _isMobilePlatformForTesting = null;

  // The testable constructor now accepts an optional parameter to simulate the platform.
  @visibleForTesting
  NotificationSettingsRepository.testable(
      this._prefsForTesting, this._workmanagerForTesting, {bool isMobile = true})
      : _isMobilePlatformForTesting = isMobile;

  static const weatherAlertsEnabledKey = 'weatherAlertsEnabled';
  static const weatherAlertsTaskId = 'weather_alert_task_id';
  static const weatherAlertsTaskName = 'weatherAlertTask';
  // ... (other constants preserved) ...
  static const eveningForecastEnabledKey = 'eveningForecastEnabled';
  static const eveningForecastTaskId = 'evening_forecast_task_id';
  static const eveningForecastTaskName = 'eveningWeatherForecastTask';

  static const imminentRainEnabledKey = 'imminentRainEnabled';
  static const imminentRainTaskId = 'imminent_rain_task_id';
  static const imminentRainTaskName = 'imminentRainTask';


  bool get _isMobilePlatform {
    // --- START OF MODIFICATION 2 of 2 ---
    // The test override now takes precedence.
    if (_isMobilePlatformForTesting != null) return _isMobilePlatformForTesting!;
    // --- END OF MODIFICATION 2 of 2 ---
    
    if (kIsWeb) return false;
    // Your original logic is preserved for production.
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  // All getter methods remain unchanged.
  Future<bool> isWeatherAlertsEnabled() async {
    final prefs = _prefsForTesting ?? await SharedPreferences.getInstance();
    return prefs.getBool(weatherAlertsEnabledKey) ?? false;
  }
  Future<bool> isEveningForecastEnabled() async {
    final prefs = _prefsForTesting ?? await SharedPreferences.getInstance();
    return prefs.getBool(eveningForecastEnabledKey) ?? false;
  }
  Future<bool> isImminentRainEnabled() async {
    final prefs = _prefsForTesting ?? await SharedPreferences.getInstance();
    return prefs.getBool(imminentRainEnabledKey) ?? false;
  }

  // All update methods now use the injected mock correctly.
  Future<void> updateWeatherAlertsSetting(bool isEnabled) async {
    final prefs = _prefsForTesting ?? await SharedPreferences.getInstance();
    final workmanager = _workmanagerForTesting ?? WorkmanagerWrapper();
    await prefs.setBool(weatherAlertsEnabledKey, isEnabled);

    if (_isMobilePlatform) {
      if (isEnabled) {
        await workmanager.registerPeriodicTask(
          weatherAlertsTaskId,
          weatherAlertsTaskName,
          frequency: const Duration(hours: 1),
          constraints: Constraints(networkType: NetworkType.connected),
        );
        log("Weather alerts task registered.", name: "NotificationSettingsRepo");
      } else {
        await workmanager.cancelByUniqueName(weatherAlertsTaskId);
        log("Weather alerts task canceled.", name: "NotificationSettingsRepo");
      }
    }
  }

  Future<void> updateEveningForecastSetting(bool isEnabled) async {
    final prefs = _prefsForTesting ?? await SharedPreferences.getInstance();
    final workmanager = _workmanagerForTesting ?? WorkmanagerWrapper();
    await prefs.setBool(eveningForecastEnabledKey, isEnabled);

    if (_isMobilePlatform) {
      if (isEnabled) {
        await workmanager.registerPeriodicTask(
          eveningForecastTaskId,
          eveningForecastTaskName,
          frequency: const Duration(days: 1),
          constraints: Constraints(networkType: NetworkType.connected),
        );
        log("Evening forecast task registered.", name: "NotificationSettingsRepo");
      } else {
        await workmanager.cancelByUniqueName(eveningForecastTaskId);
        log("Evening forecast task canceled.", name: "NotificationSettingsRepo");
      }
    }
  }

  Future<void> updateImminentRainSetting(bool isEnabled) async {
    final prefs = _prefsForTesting ?? await SharedPreferences.getInstance();
    final workmanager = _workmanagerForTesting ?? WorkmanagerWrapper();
    await prefs.setBool(imminentRainEnabledKey, isEnabled);

    if (_isMobilePlatform) {
      if (isEnabled) {
        await workmanager.registerPeriodicTask(
          imminentRainTaskId,
          imminentRainTaskName,
          frequency: const Duration(minutes: 30),
          constraints: Constraints(networkType: NetworkType.connected),
        );
        log("Imminent rain task registered.", name: "NotificationSettingsRepo");
      } else {
        await workmanager.cancelByUniqueName(imminentRainTaskId);
        log("Imminent rain task canceled.", name: "NotificationSettingsRepo");
      }
    }
  }
}
