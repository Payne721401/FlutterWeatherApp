import '../../../../services/firestore_service.dart';
import '../../../../services/location_service.dart';
import '../../data/models/observation_data.dart';
import 'dart:developer';

abstract class ObservationRepository {
  Future<ObservationData?> getNearestObservation({
    double? latitude,
    double? longitude,
    bool forceRefresh = false,
  });
}

class ObservationRepositoryImpl implements ObservationRepository {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  static const String _logName = 'ObservationRepository';

  ObservationRepositoryImpl(this._firestoreService, this._locationService);

  @override
  Future<ObservationData?> getNearestObservation({
    double? latitude,
    double? longitude,
    bool forceRefresh = false,
  }) async {
    try {
      double lat = latitude ?? 0;
      double lon = longitude ?? 0;

      if (latitude == null || longitude == null) {
        log('Coordinates not provided, fetching current location.', name: _logName);
        final position = await _locationService.getCurrentLocation();
        lat = position.latitude;
        lon = position.longitude;
      }

      return await _firestoreService.fetchNearestObservation(
        latitude: lat,
        longitude: lon,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      log('Error fetching nearest observation in repository: $e', name: _logName);
      return null;
    }
  }
}
