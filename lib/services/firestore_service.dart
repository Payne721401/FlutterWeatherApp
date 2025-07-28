import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/weather_forecast.dart';
import '../features/weather/data/models/air_quality.dart';
import '../features/weather/data/models/uv_index_data.dart';
import '../features/weather/data/models/observation_data.dart';
import '../features/weather/data/models/sunrise_sunset_data.dart'; // CORRECTED IMPORT
import '../utils/geohash_util.dart';

// Define a new enum for cache types
enum CacheType {
  currentLocation,
  searchResult,
  nearestAirQuality,
  nearestUVIndex,
  nearestObservation,
  sunriseSunset,
  weatherForecast,
}

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Caches for data by location ID
  Map<String, Map<String, dynamic>> _cachedCurrentLocationCombinedData = {};
  Map<String, DateTime> _lastCurrentLocationFetchTime = {};
  Map<String, Map<String, dynamic>> _cachedSearchResultsCombinedData = {};
  Map<String, DateTime> _lastSearchResultsFetchTime = {};
  
  // New: Dedicated caches for separated data types
  Map<String, WeatherForecast> _cachedWeatherForecasts = {};
  Map<String, DateTime> _lastWeatherForecastFetchTime = {};
  Map<String, SunriseSunsetData> _cachedSunriseSunset = {};
  Map<String, DateTime> _lastSunriseSunsetFetchTime = {};

  // Caches for nearest data by geographic location
  Map<String, AirQuality> _cachedNearestAirQuality = {};
  Map<String, DateTime> _lastNearestAirQualityFetchTime = {};
  Map<String, UVIndexData> _cachedNearestUVIndex = {};
  Map<String, DateTime> _lastNearestUVIndexFetchTime = {};
  Map<String, ObservationData> _cachedNearestObservation = {};
  Map<String, DateTime> _lastNearestObservationFetchTime = {};

  final Duration cacheDuration = const Duration(minutes: 10);

  // Helper to check cache validity
  bool _isCacheValid(String cacheKey, CacheType type) {
    Map<String, DateTime> cacheTimeMap;
    switch (type) {
      case CacheType.currentLocation:
        cacheTimeMap = _lastCurrentLocationFetchTime;
        break;
      case CacheType.searchResult:
        cacheTimeMap = _lastSearchResultsFetchTime;
        break;
      case CacheType.nearestAirQuality:
        cacheTimeMap = _lastNearestAirQualityFetchTime;
        break;
      case CacheType.nearestUVIndex:
        cacheTimeMap = _lastNearestUVIndexFetchTime;
        break;
      case CacheType.nearestObservation:
        cacheTimeMap = _lastNearestObservationFetchTime;
        break;
      case CacheType.sunriseSunset:
        cacheTimeMap = _lastSunriseSunsetFetchTime;
        break;
      case CacheType.weatherForecast:
        cacheTimeMap = _lastWeatherForecastFetchTime;
        break;
    }
    final lastFetch = cacheTimeMap[cacheKey];
    if (lastFetch == null) {
      return false;
    }
    return DateTime.now().difference(lastFetch) < cacheDuration;
  }

  // (DEPRECATED) Kept for backward compatibility during refactoring.
  Future<Map<String, dynamic>?> fetchWeatherForecastByLocation(
    String locationId, {
    bool forceRefresh = false,
    CacheType type = CacheType.currentLocation,
  }) async {
    print("Warning: fetchWeatherForecastByLocation is deprecated. Use fetchWeatherForecast and fetchSunriseSunset instead.");
    if (type != CacheType.currentLocation && type != CacheType.searchResult) {
      return null;
    }
    
    Map<String, Map<String, dynamic>> cacheDataMap = type == CacheType.currentLocation 
        ? _cachedCurrentLocationCombinedData 
        : _cachedSearchResultsCombinedData;
    Map<String, DateTime> cacheTimeMap = type == CacheType.currentLocation 
        ? _lastCurrentLocationFetchTime 
        : _lastSearchResultsFetchTime;

    if (!forceRefresh && _isCacheValid(locationId, type)) {
      print("Returning cached combined weather data for $locationId");
      return cacheDataMap[locationId];
    }

    print("Fetching combined weather data for $locationId from Firestore");

    try {
      final parts = locationId.split('_');
      final countyName = parts.isNotEmpty ? parts[0] : locationId;
      
      final results = await Future.wait([
        _firestore.collection('weather_forecasts').doc(locationId).get(),
        _firestore.collection('sunrise_sunset').doc(countyName).get(),
      ]);

      final weatherDoc = results[0];
      final sunriseSunsetDoc = results[1];

      if (weatherDoc.exists && weatherDoc.data() != null) {
        final combinedData = {
          'weatherForecast': WeatherForecast.fromDocument(weatherDoc.data() as Map<String, dynamic>, weatherDoc.id),
          'sunriseSunsetData': sunriseSunsetDoc.data(), // This remains a Map
        };
        cacheDataMap[locationId] = combinedData;
        cacheTimeMap[locationId] = DateTime.now();
        notifyListeners();
        return combinedData;
      }
    } catch (e) {
      print("Error in deprecated fetchWeatherForecastByLocation: $e");
    }
    return null;
  }
  
  /// New: Fetches only the WeatherForecast data.
  Future<WeatherForecast?> fetchWeatherForecast(String locationId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(locationId, CacheType.weatherForecast)) {
      print("Returning cached weather forecast for $locationId");
      return _cachedWeatherForecasts[locationId];
    }

    print("Fetching weather forecast for $locationId from Firestore");
    try {
      final doc = await _firestore.collection('weather_forecasts').doc(locationId).get();
      if (doc.exists && doc.data() != null) {
        final forecast = WeatherForecast.fromDocument(doc.data() as Map<String, dynamic>, doc.id);
        _cachedWeatherForecasts[locationId] = forecast;
        _lastWeatherForecastFetchTime[locationId] = DateTime.now();
        notifyListeners();
        return forecast;
      }
    } catch (e) {
      print("Error fetching weather forecast for $locationId: $e");
    }
    return null;
  }
  
  /// New: Fetches only the sunrise and sunset data by county name.
  Future<SunriseSunsetData?> fetchSunriseSunset(String countyName, {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(countyName, CacheType.sunriseSunset)) {
      print("Returning cached sunrise/sunset data for $countyName");
      return _cachedSunriseSunset[countyName];
    }

    print("Fetching sunrise/sunset data for $countyName from Firestore");
    try {
      final doc = await _firestore.collection('sunrise_sunset').doc(countyName).get();
      if (doc.exists && doc.data() != null) {
        final data = SunriseSunsetData.fromMap(doc.data()!);
        _cachedSunriseSunset[countyName] = data;
        _lastSunriseSunsetFetchTime[countyName] = DateTime.now();
        notifyListeners();
        return data;
      }
    } catch (e) {
      print("Error fetching sunrise/sunset data for $countyName: $e");
    }
    return null;
  }

  // Generic helper for concentric circle search
  Future<T?> _fetchNearestData<T>({
    required double latitude,
    required double longitude,
    required String collectionName,
    required T Function(Map<String, dynamic> data, String docId) fromDocument,
    required Map<String, T> cache,
    required Map<String, DateTime> cacheTime,
    required CacheType cacheType,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (!forceRefresh && _isCacheValid(cacheKey, cacheType)) {
      print("Returning cached nearest $collectionName data for $cacheKey");
      return cache[cacheKey];
    }

    print("Fetching nearest $collectionName for ($latitude, $longitude) using concentric search.");
    
    final List<double> searchRadii = [10.0, 30.0, 80.0, 150.0];

    for (final radiusKm in searchRadii) {
      print("Searching for $collectionName within $radiusKm km...");
      try {
        final precision = GeohashUtil.getGeohashLengthForRadius(radiusKm);
        final searchGeohashes = GeohashUtil.getGeohashNeighbors(latitude, longitude, precision);

        final queries = searchGeohashes.map((prefix) =>
            _firestore.collection(collectionName)
                .where('geohash', isGreaterThanOrEqualTo: prefix)
                .where('geohash', isLessThan: '$prefix~').get());

        final querySnapshots = await Future.wait(queries);

        final matchingDocs = <QueryDocumentSnapshot>[];
        for (final snapshot in querySnapshots) {
          matchingDocs.addAll(snapshot.docs);
        }

        if (matchingDocs.isEmpty) continue;

        T? nearestItem;
        double minDistance = double.infinity;

        for (var doc in matchingDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final docLatitude = (data['latitude'] as num?)?.toDouble() ?? (data['location'] as Map<String, dynamic>?)?['latitude'] as double?;
          final docLongitude = (data['longitude'] as num?)?.toDouble() ?? (data['location'] as Map<String, dynamic>?)?['longitude'] as double?;

          if (docLatitude != null && docLongitude != null) {
            final distance = GeohashUtil.calculateDistance(latitude, longitude, docLatitude, docLongitude);
            if (distance <= radiusKm && distance < minDistance) {
              minDistance = distance;
              nearestItem = fromDocument(data, doc.id);
            }
          }
        }

        if (nearestItem != null) {
          final stationName = (nearestItem as dynamic).stationName;
          print("Found nearest $collectionName at station '$stationName' (${minDistance.toStringAsFixed(2)} km) within $radiusKm km radius.");
          cache[cacheKey] = nearestItem;
          cacheTime[cacheKey] = DateTime.now();
          notifyListeners();
          return nearestItem;
        }
      } catch (e) {
        print("Error fetching nearest $collectionName within $radiusKm km: $e");
        continue;
      }
    }

    print("No $collectionName found within the maximum search radius.");
    return null;
  }

  // Specific fetch methods for nearest data
  Future<AirQuality?> fetchNearestAirQuality({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    return _fetchNearestData<AirQuality>(
      latitude: latitude,
      longitude: longitude,
      collectionName: 'air_quality',
      fromDocument: (data, docId) => AirQuality.fromDocument(data, docId),
      cache: _cachedNearestAirQuality,
      cacheTime: _lastNearestAirQualityFetchTime,
      cacheType: CacheType.nearestAirQuality,
      forceRefresh: forceRefresh,
    );
  }

  Future<UVIndexData?> fetchNearestUVIndex({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    return _fetchNearestData<UVIndexData>(
      latitude: latitude,
      longitude: longitude,
      collectionName: 'uv_index',
      fromDocument: (data, docId) => UVIndexData.fromDocument(data, docId),
      cache: _cachedNearestUVIndex,
      cacheTime: _lastNearestUVIndexFetchTime,
      cacheType: CacheType.nearestUVIndex,
      forceRefresh: forceRefresh,
    );
  }

  Future<ObservationData?> fetchNearestObservation({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    return _fetchNearestData<ObservationData>(
      latitude: latitude,
      longitude: longitude,
      collectionName: 'observations',
      fromDocument: (data, docId) => ObservationData.fromDocument(data, docId),
      cache: _cachedNearestObservation,
      cacheTime: _lastNearestObservationFetchTime,
      cacheType: CacheType.nearestObservation,
      forceRefresh: forceRefresh,
    );
  }
}
