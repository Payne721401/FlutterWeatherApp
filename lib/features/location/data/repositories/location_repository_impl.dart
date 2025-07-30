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
  Future<void> saveLocation(LocationData location) async {
    final savedLocations = await getSavedLocations();
    if (!savedLocations.any((l) => l.name == location.name)) {
      savedLocations.add(location);
      await _locationStorageService.saveLocations(savedLocations);
    }
  }

  @override
  Future<void> removeLocation(String locationName) async {
    final savedLocations = await getSavedLocations();
    savedLocations.removeWhere((l) => l.name == locationName);
    await _locationStorageService.saveLocations(savedLocations);
  }

  @override
  Future<List<LocationData>> getRecentSearches() {
    return _locationStorageService.getRecentSearches();
  }

  @override
  Future<void> saveRecentSearch(LocationData location) {
    return _locationStorageService.saveRecentSearch(location);
  }
}
