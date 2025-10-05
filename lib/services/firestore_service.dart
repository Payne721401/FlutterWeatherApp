import 'dart:developer';

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
  final Map<String, Map<String, dynamic>> _cachedCurrentLocationCombinedData = {};
  final Map<String, DateTime> _lastCurrentLocationFetchTime = {};
  final Map<String, Map<String, dynamic>> _cachedSearchResultsCombinedData = {};
  final Map<String, DateTime> _lastSearchResultsFetchTime = {};
  
  // New: Dedicated caches for separated data types
  final Map<String, WeatherForecast> _cachedWeatherForecasts = {};
  final Map<String, DateTime> _lastWeatherForecastFetchTime = {};
  final Map<String, SunriseSunsetData> _cachedSunriseSunset = {};
  final Map<String, DateTime> _lastSunriseSunsetFetchTime = {};

  // Caches for nearest data by geographic location
  final Map<String, AirQuality> _cachedNearestAirQuality = {};
  final Map<String, DateTime> _lastNearestAirQualityFetchTime = {};
  final Map<String, UVIndexData> _cachedNearestUVIndex = {};
  final Map<String, DateTime> _lastNearestUVIndexFetchTime = {};
  final Map<String, ObservationData> _cachedNearestObservation = {};
  final Map<String, DateTime> _lastNearestObservationFetchTime = {};

  // MODIFICATION: Caches for the last found stationId (business ID) to avoid repeated geo-searches
  final Map<String, String> _cachedNearestStationId = {};
  final Map<String, Map<String, double>> _cachedNearestStationLocation = {};
  static const double _locationChangeThresholdKm = 2.0; // 2 km threshold

  // MODIFICATION: Add bounding box for Taiwan and its surrounding islands.
  static const double _taiwanBoundsNorth = 26.3;
  static const double _taiwanBoundsSouth = 21.8;
  static const double _taiwanBoundsEast = 122.1;
  static const double _taiwanBoundsWest = 118.2;

  final Duration cacheDuration = const Duration(minutes: 20);

  // MODIFICATION: Helper function to check if coordinates are within Taiwan's bounds.
  bool _isWithinTaiwanBounds(double latitude, double longitude) {
    return latitude >= _taiwanBoundsSouth &&
           latitude <= _taiwanBoundsNorth &&
           longitude >= _taiwanBoundsWest &&
           longitude <= _taiwanBoundsEast;
  }

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
    log("Warning: fetchWeatherForecastByLocation is deprecated. Use fetchWeatherForecast and fetchSunriseSunset instead.");
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
      log("Returning cached combined weather data for $locationId");
      return cacheDataMap[locationId];
    }

    log("Fetching combined weather data for $locationId from Firestore");

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
      log("Error in deprecated fetchWeatherForecastByLocation: $e");
    }
    return null;
  }
  
  /// New: Fetches only the WeatherForecast data.
  Future<WeatherForecast?> fetchWeatherForecast(String locationId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(locationId, CacheType.weatherForecast)) {
      log("Returning cached weather forecast for $locationId");
      return _cachedWeatherForecasts[locationId];
    }

    log("Fetching weather forecast for $locationId from Firestore");
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
      log("Error fetching weather forecast for $locationId: $e");
    }
    return null;
  }
  
  /// New: Fetches only the sunrise and sunset data by county name.
  Future<SunriseSunsetData?> fetchSunriseSunset(String countyName, {bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(countyName, CacheType.sunriseSunset)) {
      log("Returning cached sunrise/sunset data for $countyName");
      return _cachedSunriseSunset[countyName];
    }

    log("Fetching sunrise/sunset data for $countyName from Firestore");
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
      log("Error fetching sunrise/sunset data for $countyName: $e");
    }
    return null;
  }

  // Generic helper for concentric circle search upgraded with smart caching
  Future<T?> _fetchNearestData<T>({
    required double latitude,
    required double longitude,
    required String collectionName,
    required T Function(Map<String, dynamic> data, String docId) fromDocument,
    required Map<String, T> cache,
    required Map<String, DateTime> cacheTime,
    required CacheType cacheType,
    List<double>? customSearchRadii,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

    // CORRECTED LOGIC 1: Use 'stationId' for the smart cache check
    if (!forceRefresh && _cachedNearestStationId.containsKey(collectionName)) {
      final lastLocation = _cachedNearestStationLocation[collectionName]!;
      final distanceMoved = GeohashUtil.calculateDistance(latitude, longitude, lastLocation['lat']!, lastLocation['lon']!);
      
      if (distanceMoved < _locationChangeThresholdKm) {
        final stationId = _cachedNearestStationId[collectionName]!;
        log("User location stable (moved ${distanceMoved.toStringAsFixed(2)} km). Fetching latest data directly using cached stationId '$stationId' for $collectionName.");
        try {
          final querySnapshot = await _firestore
              .collection(collectionName)
              .where('stationId', isEqualTo: stationId)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final doc = querySnapshot.docs.first;
            final item = fromDocument(doc.data(), doc.id);
            cache[cacheKey] = item;
            cacheTime[cacheKey] = DateTime.now();
            notifyListeners();
            return item;
          }
        } catch (e) {
          log("Failed to fetch directly using cached stationId '$stationId'. Error: $e. Proceeding with geo-search.");
          _cachedNearestStationId.remove(collectionName);
          _cachedNearestStationLocation.remove(collectionName);
        }
      }
    }

    if (!forceRefresh && _isCacheValid(cacheKey, cacheType)) {
      log("Returning cached nearest $collectionName data for $cacheKey");
      return cache[cacheKey];
    }

    log("Fetching nearest $collectionName for ($latitude, $longitude) using concentric search.");
    
    final List<double> searchRadii = customSearchRadii ?? [5.0, 10.0, 30.0, 80.0, 150.0];

    for (final radiusKm in searchRadii) {
      log("Searching for $collectionName within $radiusKm km...");
      try {
        final precision = GeohashUtil.getGeohashLengthForRadius(radiusKm);
        final searchGeohashes = GeohashUtil.getGeohashNeighbors(latitude, longitude, precision);
        final bool useLimit = (radiusKm == 5.0);

        final queries = searchGeohashes.map((prefix) {
            Query query = _firestore.collection(collectionName)
                .where('geohash', isGreaterThanOrEqualTo: prefix)
                .where('geohash', isLessThan: '$prefix~');
            if (useLimit) {
              query = query.limit(1);
            }
            return query.get();
        });

        final querySnapshots = await Future.wait(queries);
        final matchingDocs = <QueryDocumentSnapshot>[];
        for (final snapshot in querySnapshots) {
          matchingDocs.addAll(snapshot.docs);
        }

        if (matchingDocs.isEmpty) continue;

        QueryDocumentSnapshot? nearestDoc;
        double minDistance = double.infinity;

        for (var doc in matchingDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final docLatitude = (data['latitude'] as num?)?.toDouble() ?? (data['location'] as Map<String, dynamic>?)?['latitude'] as double?;
          final docLongitude = (data['longitude'] as num?)?.toDouble() ?? (data['location'] as Map<String, dynamic>?)?['longitude'] as double?;

          if (docLatitude != null && docLongitude != null) {
            final distance = GeohashUtil.calculateDistance(latitude, longitude, docLatitude, docLongitude);
            if (distance <= radiusKm && distance < minDistance) {
              minDistance = distance;
              nearestDoc = doc;
            }
          }
        }

        if (nearestDoc != null) {
          final T nearestItem = fromDocument(nearestDoc.data() as Map<String, dynamic>, nearestDoc.id);
          final stationName = (nearestItem as dynamic).stationName ?? 'Unknown';
          
          log("Found nearest $collectionName at station '$stationName' (${minDistance.toStringAsFixed(2)} km) within $radiusKm km radius.");
          
          cache[cacheKey] = nearestItem;
          cacheTime[cacheKey] = DateTime.now();

          // CORRECTED LOGIC 2: Cache the 'stationId' field from the data model
          final stationIdForCache = (nearestItem as dynamic).stationId;
          _cachedNearestStationId[collectionName] = stationIdForCache;
          _cachedNearestStationLocation[collectionName] = {'lat': latitude, 'lon': longitude};
          log("Cached stationId '$stationIdForCache' for $collectionName at current location.");

          notifyListeners();
          return nearestItem;
        }
      } catch (e) {
        log("Error fetching nearest $collectionName within $radiusKm km: $e");
        continue;
      }
    }

    log("No $collectionName found within the maximum search radius.");
    return null;
  }

  // Specific fetch methods for nearest data
  Future<AirQuality?> fetchNearestAirQuality({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    // MODIFICATION: Add pre-flight check.
    if (!_isWithinTaiwanBounds(latitude, longitude)) {
      log("User is outside Taiwan's bounding box. Skipping Firestore geo-search for Air Quality.");
      return null;
    }

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
    // MODIFICATION: Add pre-flight check.
    if (!_isWithinTaiwanBounds(latitude, longitude)) {
      log("User is outside Taiwan's bounding box. Skipping Firestore geo-search for UV Index.");
      return null;
    }

    return _fetchNearestData<UVIndexData>(
      latitude: latitude,
      longitude: longitude,
      collectionName: 'uv_index',
      fromDocument: (data, docId) => UVIndexData.fromDocument(data, docId),
      cache: _cachedNearestUVIndex,
      cacheTime: _lastNearestUVIndexFetchTime,
      cacheType: CacheType.nearestUVIndex,
      customSearchRadii: [30.0, 80.0, 150.0],
      forceRefresh: forceRefresh,
    );
  }

  Future<ObservationData?> fetchNearestObservation({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) async {
    // MODIFICATION: Add pre-flight check.
    if (!_isWithinTaiwanBounds(latitude, longitude)) {
      log("User is outside Taiwan's bounding box. Skipping Firestore geo-search for Observations.");
      return null;
    }
    
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
