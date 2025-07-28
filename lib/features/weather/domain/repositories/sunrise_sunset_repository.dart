import '../../../../services/firestore_service.dart';
import '../../data/models/sunrise_sunset_data.dart'; // Contains SunriseSunsetData
import 'dart:developer';

abstract class SunriseSunsetRepository {
  Future<SunriseSunsetData?> getSunriseSunset(String countyName, {bool forceRefresh = false});
}

class SunriseSunsetRepositoryImpl implements SunriseSunsetRepository {
  final FirestoreService _firestoreService;
  static const String _logName = 'SunriseSunsetRepository';

  SunriseSunsetRepositoryImpl(this._firestoreService);

  @override
  Future<SunriseSunsetData?> getSunriseSunset(String countyName, {bool forceRefresh = false}) async {
    log('Fetching sunrise/sunset data for county: $countyName', name: _logName);
    try {
      return await _firestoreService.fetchSunriseSunset(countyName, forceRefresh: forceRefresh);
    } catch (e) {
      log('Error fetching sunrise/sunset data in repository: $e', name: _logName);
      return null;
    }
  }
}
