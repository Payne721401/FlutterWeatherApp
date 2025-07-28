import '../../data/services/alert_service.dart';
import '../../data/models/weather_alert.dart';
import 'dart:developer';

abstract class AlertRepository {
  Future<List<WeatherAlert>> fetchAlerts();
}

class AlertRepositoryImpl implements AlertRepository {
  final AlertService _alertService;
  static const String _logName = 'AlertRepository';

  AlertRepositoryImpl(this._alertService);

  @override
  Future<List<WeatherAlert>> fetchAlerts() async {
    log('Fetching alerts directly from AlertService.', name: _logName);
    try {
      // MODIFICATION: Directly call the service and return its result.
      // The service now returns the correct model, so no transformation is needed.
      final List<WeatherAlert> alerts = await _alertService.fetchAlerts();
      log('Successfully fetched ${alerts.length} alerts.', name: _logName);
      return alerts;
    } catch (e) {
      log('Error fetching alerts in repository: $e', name: _logName);
      // Return an empty list in case of an error.
      return [];
    }
  }
}
