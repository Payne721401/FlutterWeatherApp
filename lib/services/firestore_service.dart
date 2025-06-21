import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For ChangeNotifier
import '../models/weather_forecast.dart'; // Import the WeatherForecast model

// Define a new enum for cache types
enum CacheType {
  currentLocation,
  searchResult,
}

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Separate cache for current location weather forecast
  Map<String, WeatherForecast> _cachedCurrentLocationForecasts = {};
  Map<String, DateTime> _lastCurrentLocationFetchTime = {};

  // Separate cache for search results weather forecast
  Map<String, WeatherForecast> _cachedSearchResultsForecasts = {};
  Map<String, DateTime> _lastSearchResultsFetchTime = {};

  // Cache validity duration (e.g., 5 minutes)
  final Duration cacheDuration = const Duration(minutes: 5);

  // Helper to check cache validity based on CacheType
  bool _isCacheValid(String locationId, CacheType type) {
    Map<String, DateTime> cacheTimeMap;
    if (type == CacheType.currentLocation) {
      cacheTimeMap = _lastCurrentLocationFetchTime;
    } else { // CacheType.searchResult
      cacheTimeMap = _lastSearchResultsFetchTime;
    }
    final lastFetch = cacheTimeMap[locationId];
    if (lastFetch == null) {
      return false;
    }
    return DateTime.now().difference(lastFetch) < cacheDuration;
  }

  // Fetch weather forecast data by location ID (main document and weekly sub-collection)
  Future<WeatherForecast?> fetchWeatherForecastByLocation(
      String locationId, {
      bool forceRefresh = false,
      CacheType type = CacheType.currentLocation, // Default to currentLocation
      }) async {
    Map<String, WeatherForecast> cacheDataMap;
    Map<String, DateTime> cacheTimeMap;

    if (type == CacheType.currentLocation) {
      cacheDataMap = _cachedCurrentLocationForecasts;
      cacheTimeMap = _lastCurrentLocationFetchTime;
    } else { // CacheType.searchResult
      cacheDataMap = _cachedSearchResultsForecasts;
      cacheTimeMap = _lastSearchResultsFetchTime;
    }

    // Return cached data if not forced refresh and cache is valid
    if (!forceRefresh && _isCacheValid(locationId, type)) {
      print("Returning cached weather forecast for $locationId (Type: $type)");
      return cacheDataMap[locationId];
    }

    print("Fetching weather forecast for $locationId from Firestore by Document ID (Type: $type)");
    try {
      DocumentSnapshot doc = await _firestore.collection('weather_forecasts').doc(locationId).get();

      if (doc.exists && doc.data() != null) {
        final weatherForecast = WeatherForecast.fromDocument(doc.data() as Map<String, dynamic>, doc.id);
        cacheDataMap[locationId] = weatherForecast; // Update specific cache
        cacheTimeMap[locationId] = DateTime.now(); // Update specific cache timestamp
        notifyListeners(); // Notify Widgets to update
        return weatherForecast;
      } else {
        print("Document with ID '$locationId' does not exist in weather_forecasts for type $type.");
        return null;
      }
    } catch (e) {
      print("Error fetching weather forecast for $locationId (Type: $type): $e");
      return null;
    }
  }
}
