import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:intl/intl.dart'; // For date formatting
import 'dart:async';
import 'dart:developer';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Import all necessary services and repositories
import '../../../../services/location_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final ConnectivityService _connectivityService;

  // --- State Variables ---
  bool _isLoading = false;
  String? _error;
  bool _needsRetry = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // --- Location Name Management ---
  String? _currentLocationName;
  String? _selectedLocationName;

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
  // Timer? _alertUpdateTimer; // MODIFIED: Removed redundant alert timer

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get currentLocationName => _currentLocationName;
  String? get selectedLocationName => _selectedLocationName;

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

  bool get isDaytime {
    try {
      final location = tz.getLocation('Asia/Taipei');
      final now = tz.TZDateTime.now(location);
      return now.hour >= 6 && now.hour < 18;
    } catch (e) {
      log(
        'Error getting TZDateTime for isDaytime check: $e',
        name: 'WeatherDataState',
      );
      return true; // Fallback to daytime
    }
  }

  WeatherDataState({
    required AppDependencies dependencies,
    required ConnectivityService connectivityService,
  }) : _locationService = dependencies.locationService,
       _alertRepository = dependencies.alertRepository,
       _forecastRepository = dependencies.weatherForecastRepository,
       _sunriseSunsetRepository = dependencies.sunriseSunsetRepository,
       _airQualityRepository = dependencies.airQualityRepository,
       _uvIndexRepository = dependencies.uvIndexRepository,
       _observationRepository = dependencies.observationRepository,
       _connectivityService = connectivityService {
    _initialize();
  }

  void _initialize() {
    tz.initializeTimeZones();

    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      results,
    ) {
      final hasInternet = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasInternet && _needsRetry) {
        log(
          'Internet connection restored, retrying data fetch...',
          name: 'WeatherDataState',
        );
        fetchDataForCurrentLocation();
      }
    });

    _dataUpdateTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => fetchDataForCurrentLocation(isPeriodicUpdate: true),
    );
    // _alertUpdateTimer = Timer.periodic(const Duration(minutes: 30), (_) => _fetchAlerts()); // MODIFIED: Removed redundant alert timer
  }

  Future<void> fetchDataForCurrentLocation({
    bool isPeriodicUpdate = false,
    bool forceRefresh = false,
  }) async {
    if (!isPeriodicUpdate) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _error = null;
      _needsRetry = false;

      final position = await _locationService.getCurrentLocation();
      final adminDivision = await _locationService.getAdministrativeDivision(
        position.latitude,
        position.longitude,
      );

      if (adminDivision != null) {
        _currentLocationName = adminDivision;
        _selectedLocationName = adminDivision;

        await _fetchAllData(
          adminDivision.replaceAll(' ', '_'),
          latitude: position.latitude,
          longitude: position.longitude,
          forceRefresh: forceRefresh,
        );
      } else {
        _error = "無法識別您目前的位置。服務範圍僅限台灣地區，請嘗試手動搜尋地點。";
        _needsRetry = true;
      }
    } catch (e) {
      log(
        'Error fetching data for current location: $e',
        name: 'WeatherDataState',
      );
      _error = "無法獲取當前位置的資料。";
      _needsRetry = true; // Set retry flag on general failure
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
    _selectedLocationName = locationData.name;
    notifyListeners();
    try {
      _error = null;
      _needsRetry = false;

      await _fetchAllData(
        locationData.name.replaceAll(' ', '_'),
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        forceRefresh: true,
      );
    } catch (e) {
      log(
        'Error fetching data for searched location "${locationData.name}": $e',
        name: 'WeatherDataState',
      );
      _error = "無法獲取 '${locationData.name}' 的資料。";
      _needsRetry = true; // Set retry flag
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAllData(
    String locationId, {
    double? latitude,
    double? longitude,
    bool forceRefresh = false,
  }) async {
    final countyName = locationId.split('_').first;

    try {
      final results = await Future.wait([
        _forecastRepository.getForecastData(
          locationId,
          forceRefresh: forceRefresh,
        ),
        _sunriseSunsetRepository.getSunriseSunset(
          countyName,
          forceRefresh: forceRefresh,
        ),
        _airQualityRepository.getNearestAirQuality(
          latitude: latitude,
          longitude: longitude,
          forceRefresh: forceRefresh,
        ),
        _uvIndexRepository.getNearestUVIndex(
          latitude: latitude,
          longitude: longitude,
          forceRefresh: forceRefresh,
        ),
        _observationRepository.getNearestObservation(
          latitude: latitude,
          longitude: longitude,
          forceRefresh: forceRefresh,
        ),
        _alertRepository.fetchAlerts(),
      ]);

      // --- Success Path ---
      _needsRetry = false; // We succeeded, so no retry is needed.
      _error = null; // Clear any previous errors.

      final uiBundle = results[0] as UIWeatherDataBundle?;
      _sunriseSunset = results[1] as SunriseSunsetData?;
      _airQuality = results[2] as AirQuality?;
      _uvIndex = results[3] as UVIndexData?;
      _observation = results[4] as ObservationData?;

      // --- MODIFICATION START: De-duplicate alerts ---
      final rawAlerts = results[5] as List<WeatherAlert>;
      final Map<String, WeatherAlert> uniqueAlerts = {};
      for (final alert in rawAlerts) {
        final existingAlert = uniqueAlerts[alert.title];
        if (existingAlert == null ||
            alert.issuedTime.isAfter(existingAlert.issuedTime)) {
          uniqueAlerts[alert.title] = alert;
        }
      }
      _alerts = uniqueAlerts.values.toList();
      // --- MODIFICATION END ---

      if (uiBundle != null) {
        _condition = uiBundle.condition;
        _conditionIcon = uiBundle.conditionIcon;
        _temperature = uiBundle.temperature; // Corrected typo
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
      // --- Failure Path ---
      log(
        'A critical error occurred in _fetchAllData: $e',
        name: 'WeatherDataState',
      );
      // Re-throw the exception so the caller's catch block can handle setting
      // the error message and the _needsRetry flag.
      throw e;
    }
    notifyListeners();
  }

  // MODIFIED: This method is now redundant and has been removed.
  // Future<void> _fetchAlerts() async { ... }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    // _alertUpdateTimer?.cancel(); // MODIFIED: Removed redundant alert timer
    _connectivitySubscription?.cancel();
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
    airQualityRepository = AirQualityRepositoryImpl(
      firestoreService,
      locationService,
    );
    uvIndexRepository = UVIndexRepositoryImpl(
      firestoreService,
      locationService,
    );
    observationRepository = ObservationRepositoryImpl(
      firestoreService,
      locationService,
    );
  }
}
