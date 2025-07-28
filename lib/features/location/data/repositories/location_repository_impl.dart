import '../models/location_data.dart';
import '../services/location_storage_service.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationStorageService _locationStorageService;

  LocationRepositoryImpl(this._locationStorageService);

  @override
  Future<List<LocationData>> getSavedLocations() {
    return _locationStorageService.getSavedLocations();
  }

  @override
  Future<void> saveLocation(LocationData location) {
    return _locationStorageService.saveLocation(location);
  }

  @override
  Future<void> removeLocation(String locationName) {
    return _locationStorageService.removeLocation(locationName);
  }
}