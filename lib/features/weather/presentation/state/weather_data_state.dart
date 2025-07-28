import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:intl/intl.dart'; // For date formatting
import 'dart:async';
import 'dart:developer';

// Import all necessary services and repositories
import '../../../../services/location_service.dart';
import '../../../../services/firestore_service.dart';
import '../../data/services/alert_service.dart';
import '../../domain/repositories/weather_forecast_repository.dart';
import '../../domain/repositories/sunrise_sunset_repository.dart';
import '../../domain/repositories/air_quality_repository.dart';
import '../../domain/repositories/uv_index_repository.dart';
import '../../domain/repositories/observation_repository.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../../location/data/models/location_data.dart'; // Import LocationData

// Corrected: Import all necessary data models from their separated files
import '../../data/models/sunrise_sunset_data.dart';
import '../../data/models/weather_alert.dart';
import '../../data/models/air_quality.dart';
import '../../data/models/uv_index_data.dart';
import '../../data/models/observation_data.dart';
import '../../data/models/ui_weather_forecast.dart';

class WeatherDataState extends ChangeNotifier {
  // --- Injected Dependencies ---
  final LocationService _locationService;
  final AlertRepository _alertRepository;
  final WeatherForecastRepository _forecastRepository;
  final SunriseSunsetRepository _sunriseSunsetRepository;
  final AirQualityRepository _airQualityRepository;
  final UVIndexRepository _uvIndexRepository;
  final ObservationRepository _observationRepository;

  // --- State Variables ---
  bool _isLoading = false;
  String? _error;
  String? _currentLocationName;
  
  // Data models for UI
  AirQuality? _airQuality;
  UVIndexData? _uvIndex;
  ObservationData? _observation;
  SunriseSunsetData? _sunriseSunset;
  List<WeatherAlert> _alerts = [];
  
  // UI-specific, transformed forecast data
  String? _condition;
  String? _conditionIcon;
  double? _temperature;
  double? _tempHigh;
  double? _tempLow;
  List<HourlyForecast> _hourlyForecasts = [];
  List<DailyForecast> _dailyForecasts = [];

  // Timers for periodic updates
  Timer? _dataUpdateTimer;
  Timer? _alertUpdateTimer;

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentLocationName => _currentLocationName;
  AirQuality? get airQuality => _airQuality;
  UVIndexData? get uvIndex => _uvIndex;
  ObservationData? get observation => _observation;
  SunriseSunsetData? get sunriseSunset => _sunriseSunset;
  List<WeatherAlert> get alerts => _alerts;
  String? get condition => _condition;
  String? get conditionIcon => _conditionIcon;
  double? get temperature => _temperature;
  double? get tempHigh => _tempHigh;
  double? get tempLow => _tempLow;
  List<HourlyForecast> get hourlyForecasts => _hourlyForecasts;
  List<DailyForecast> get dailyForecasts => _dailyForecasts;
  
  WeatherDataState({
    required AppDependencies dependencies,
  }) : _locationService = dependencies.locationService,
       _alertRepository = dependencies.alertRepository,
       _forecastRepository = dependencies.weatherForecastRepository,
       _sunriseSunsetRepository = dependencies.sunriseSunsetRepository,
       _airQualityRepository = dependencies.airQualityRepository,
       _uvIndexRepository = dependencies.uvIndexRepository,
       _observationRepository = dependencies.observationRepository {
    _initialize();
  }

  void _initialize() {
    fetchDataForCurrentLocation();
    _dataUpdateTimer = Timer.periodic(const Duration(minutes: 10), (_) => fetchDataForCurrentLocation(isPeriodicUpdate: true));
    _alertUpdateTimer = Timer.periodic(const Duration(minutes: 30), (_) => _fetchAlerts());
  }

  Future<void> fetchDataForCurrentLocation({bool isPeriodicUpdate = false, bool forceRefresh = false}) async {
    if (!isPeriodicUpdate) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final position = await _locationService.getCurrentLocation();
      final adminDivision = await _locationService.getAdministrativeDivision(position.latitude, position.longitude);
      if (adminDivision != null) {
        _currentLocationName = adminDivision;
        // Pass the precise coordinates for observation data
        await _fetchAllData(
          adminDivision.replaceAll(' ', '_'), 
          latitude: position.latitude, 
          longitude: position.longitude, 
          forceRefresh: forceRefresh
        );
      } else {
        throw Exception("Could not determine administrative division.");
      }
    } catch (e) {
      log('Error fetching data for current location: $e', name: 'WeatherDataState');
      _error = "無法獲取當前位置的資料。";
    } finally {
      if (!isPeriodicUpdate) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> fetchDataForSearchedLocation(LocationData locationData) async {
    _isLoading = true;
    _currentLocationName = locationData.name;
    notifyListeners();
    try {
      // Pass both the name for forecast and coordinates for observation
      await _fetchAllData(
        locationData.name.replaceAll(' ', '_'), 
        latitude: locationData.latitude, 
        longitude: locationData.longitude, 
        forceRefresh: true
      );
    } catch (e) {
      log('Error fetching data for searched location "${locationData.name}": $e', name: 'WeatherDataState');
      _error = "無法獲取 '${locationData.name}' 的資料。";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _fetchAllData(String locationId, {double? latitude, double? longitude, bool forceRefresh = false}) async {
    _error = null;
    final countyName = locationId.split('_').first;

    try {
      final results = await Future.wait([
        _forecastRepository.getForecastData(locationId, forceRefresh: forceRefresh),
        _sunriseSunsetRepository.getSunriseSunset(countyName, forceRefresh: forceRefresh),
        // Pass coordinates to observation repositories
        _airQualityRepository.getNearestAirQuality(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh),
        _uvIndexRepository.getNearestUVIndex(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh),
        _observationRepository.getNearestObservation(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh),
        _alertRepository.fetchAlerts(),
      ]);
      
      final uiBundle = results[0] as UIWeatherDataBundle?;
      _sunriseSunset = results[1] as SunriseSunsetData?;
      _airQuality = results[2] as AirQuality?;
      _uvIndex = results[3] as UVIndexData?;
      _observation = results[4] as ObservationData?;
      _alerts = results[5] as List<WeatherAlert>;
      
      if (uiBundle != null) {
        _condition = uiBundle.condition;
        _conditionIcon = uiBundle.conditionIcon;
        _temperature = uiBundle.temperature;
        _tempHigh = uiBundle.tempHigh;
        _tempLow = uiBundle.tempLow;
        _hourlyForecasts = uiBundle.hourlyForecasts;
        _dailyForecasts = uiBundle.dailyForecasts;
      } else {
        _condition = null;
        _conditionIcon = null;
        _temperature = null;
        _tempHigh = null;
        _tempLow = null;
        _hourlyForecasts = [];
        _dailyForecasts = [];
      }

    } catch (e) {
      log('A critical error occurred in _fetchAllData: $e', name: 'WeatherDataState');
      _error = "獲取資料時發生嚴重錯誤。";
    }
    notifyListeners();
  }
  
  Future<void> _fetchAlerts() async {
    try {
      _alerts = await _alertRepository.fetchAlerts();
      notifyListeners();
    } catch (e) {
      log('Error during periodic alert fetch: ' + e.toString(), name: 'WeatherDataState');
    }
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    _alertUpdateTimer?.cancel();
    super.dispose();
  }
}

// Helper class for dependency injection
class AppDependencies {
  final LocationService locationService = LocationService();
  final FirestoreService firestoreService = FirestoreService();
  final AlertService alertService = AlertService();

  late final AlertRepository alertRepository;
  late final WeatherForecastRepository weatherForecastRepository;
  late final SunriseSunsetRepository sunriseSunsetRepository;
  late final AirQualityRepository airQualityRepository;
  late final UVIndexRepository uvIndexRepository;
  late final ObservationRepository observationRepository;

  AppDependencies() {
    alertRepository = AlertRepositoryImpl(alertService);
    weatherForecastRepository = WeatherForecastRepositoryImpl(firestoreService);
    sunriseSunsetRepository = SunriseSunsetRepositoryImpl(firestoreService);
    airQualityRepository = AirQualityRepositoryImpl(firestoreService, locationService);
    uvIndexRepository = UVIndexRepositoryImpl(firestoreService, locationService);
    observationRepository = ObservationRepositoryImpl(firestoreService, locationService);
  }
}
