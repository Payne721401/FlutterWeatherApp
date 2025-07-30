import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_data.dart';

class LocationStorageService {
  static const _savedLocationsKey = 'saved_locations';
  static const _recentSearchesKey = 'recent_searches';
  static const _maxRecentSearches = 5;

  Future<void> saveLocations(List<LocationData> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final locationStrings =
        locations.map((loc) => jsonEncode(loc.toJson())).toList();
    await prefs.setStringList(_savedLocationsKey, locationStrings);
  }

  Future<List<LocationData>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationStrings = prefs.getStringList(_savedLocationsKey) ?? [];
    return locationStrings
        .map((str) => LocationData.fromJson(jsonDecode(str)))
        .toList();
  }

  Future<void> saveRecentSearch(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    final recentSearches = await getRecentSearches();

    // Remove if already exists to move it to the top
    recentSearches.removeWhere((l) => l.name == location.name);

    // Add to the top
    recentSearches.insert(0, location);

    // Trim the list if it's too long
    final trimmedList = recentSearches.length > _maxRecentSearches
        ? recentSearches.sublist(0, _maxRecentSearches)
        : recentSearches;
    
    final locationStrings =
        trimmedList.map((loc) => jsonEncode(loc.toJson())).toList();
    await prefs.setStringList(_recentSearchesKey, locationStrings);
  }

  Future<List<LocationData>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final locationStrings = prefs.getStringList(_recentSearchesKey) ?? [];
    if (locationStrings.isEmpty) {
      return [];
    }
    return locationStrings
        .map((str) {
          try {
            return LocationData.fromJson(jsonDecode(str));
          } catch (e) {
            // Handle potential malformed JSON
            print('Error decoding recent search location: $e');
            return null;
          }
        })
        .where((loc) => loc != null)
        .cast<LocationData>()
        .toList();
  }
}
