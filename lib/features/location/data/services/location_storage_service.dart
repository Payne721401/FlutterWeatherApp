import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_data.dart';

class LocationStorageService {
  static const String _savedLocationsKey = 'savedLocations';

  Future<List<LocationData>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedLocationsJson = prefs.getStringList(_savedLocationsKey) ?? [];
    return savedLocationsJson.map((jsonString) => LocationData.fromJson(json.decode(jsonString))).toList();
  }

  Future<void> saveLocation(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    List<LocationData> savedLocations = await getSavedLocations();
    if (!savedLocations.contains(location)) {
      savedLocations.add(location);
      final List<String> updatedLocationsJson = savedLocations.map((loc) => json.encode(loc.toJson())).toList();
      await prefs.setStringList(_savedLocationsKey, updatedLocationsJson);
    }
  }

  Future<void> removeLocation(String locationName) async {
    final prefs = await SharedPreferences.getInstance();
    List<LocationData> savedLocations = await getSavedLocations();
    savedLocations.removeWhere((loc) => loc.name == locationName);
    final List<String> updatedLocationsJson = savedLocations.map((loc) => json.encode(loc.toJson())).toList();
    await prefs.setStringList(_savedLocationsKey, updatedLocationsJson);
  }
}