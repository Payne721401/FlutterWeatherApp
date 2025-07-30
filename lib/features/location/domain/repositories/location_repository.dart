import '../../data/models/location_data.dart';

abstract class LocationRepository {
  Future<List<LocationData>> getSavedLocations();
  Future<void> saveLocation(LocationData location);
  Future<void> removeLocation(String locationName);
  Future<List<LocationData>> getRecentSearches();
  Future<void> saveRecentSearch(LocationData location);
}
