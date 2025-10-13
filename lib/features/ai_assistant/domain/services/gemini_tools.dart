import 'package:weatherpro/features/location/data/models/location_data.dart';
import 'package:weatherpro/features/radar/data/services/radar_forecast_service.dart';
import 'package:weatherpro/features/radar/utils/rainfall_calculator.dart';
import 'package:weatherpro/features/weather/domain/repositories/air_quality_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/observation_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/uv_index_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/weather_forecast_repository.dart';
import 'package:weatherpro/features/weather/presentation/state/weather_data_state.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:weatherpro/services/location_service.dart';
import 'package:weatherpro/utils/taiwan_township_coordinates.dart';

// A private helper class to store the result of location resolution.
class _ResolvedLocation {
  final double latitude;
  final double longitude;
  final String? locationId; // For forecast repository

  _ResolvedLocation({required this.latitude, required this.longitude, this.locationId});
}

/// A dedicated class to handle all Gemini tool-related logic.
class GeminiTools {
  final WeatherDataState _weatherDataState;
  final LocationService _locationService;
  final RadarForecastService _radarForecastService;
  final ObservationRepository _observationRepository;
  final UVIndexRepository _uvIndexRepository;
  final AirQualityRepository _airQualityRepository;
  final WeatherForecastRepository _weatherForecastRepository;

  GeminiTools({
    required WeatherDataState weatherDataState,
    required LocationService locationService,
    required RadarForecastService radarForecastService,
    required ObservationRepository observationRepository,
    required UVIndexRepository uvIndexRepository,
    required AirQualityRepository airQualityRepository,
    required WeatherForecastRepository weatherForecastRepository,
  })  : _weatherDataState = weatherDataState,
        _locationService = locationService,
        _radarForecastService = radarForecastService,
        _observationRepository = observationRepository,
        _uvIndexRepository = uvIndexRepository,
        _airQualityRepository = airQualityRepository,
        _weatherForecastRepository = weatherForecastRepository;

  // --- 1. Tool Declarations ---
  FunctionDeclaration get getCurrentObservationDecl => FunctionDeclaration(
        'getCurrentObservation',
        '取得指定地點的「即時」天氣觀測資料。回傳的資料包含：location (測站名稱), temperature (溫度), weather (天氣狀況文字), humidity (相對濕度), precipitation (今日累積雨量), windSpeed (風速), windDirection (風向角度)。',
        parameters: {
          'townshipName': Schema.string(description: '完整的縣市鄉鎮名稱，不含空格，例如 `臺北市信義區`。'),
          'latitude': Schema.number(description: '地標的緯度，例如 25.033。'),
          'longitude': Schema.number(description: '地標的經度，例如 121.564。'),
        },
      );

  FunctionDeclaration get getUvIndexDecl => FunctionDeclaration(
        'getUvIndex',
        '取得指定地點的「紫外線(UV)」指數。回傳的資料包含：location (測站名稱), uvIndex (UV指數數值), level (紫外線等級)。',
        parameters: {
          'townshipName': Schema.string(description: '完整的縣市鄉鎮名稱，不含空格，例如 `臺北市信義區`。'),
          'latitude': Schema.number(description: '地標的緯度。'),
          'longitude': Schema.number(description: '地標的經度。'),
        },
      );

  FunctionDeclaration get getAirQualityDecl => FunctionDeclaration(
        'getAirQuality',
        '取得指定地點的「空氣品質」資訊。回傳的資料包含：location (測站名稱), aqi (AQI數值), status (狀態等級文字)。',
        parameters: {
          'townshipName': Schema.string(description: '完整的縣市鄉鎮名稱，不含空格，例如 `臺北市信義區`。'),
          'latitude': Schema.number(description: '地標的緯度。'),
          'longitude': Schema.number(description: '地標的經度。'),
        },
      );

  FunctionDeclaration get getWeatherForecastDecl => FunctionDeclaration(
        'getWeatherForecast',
        '取得一個地點「未來一週」及「未來72小時」的天氣預報。回傳的資料包含兩個列表：hourlyForecasts (每3小時預報) 和 dailyForecasts (每日預報)。',
        parameters: {
          'townshipName': Schema.string(description: '完整的縣市鄉鎮名稱，不含空格，例如 `臺北市信義區`。'),
        },
      );

  FunctionDeclaration get getComprehensiveWeatherReportDecl => FunctionDeclaration(
        'getComprehensiveWeatherReport',
        '一次性取得指定地點的「完整天氣報告」。回傳一個綜合資料集，包含 location, temperature, weather, uvIndex, aqi, dailyForecasts, 和 hourlyForecasts。',
        parameters: {
          'townshipName': Schema.string(description: '完整的縣市鄉鎮名稱，不含空格，例如 `臺北市信義區`。'),
          'latitude': Schema.number(description: '地標的緯度。'),
          'longitude': Schema.number(description: '地標的經度。'),
        },
      );

  FunctionDeclaration get getOneHourRainfallDecl => FunctionDeclaration(
        'getOneHourRainfall',
        '根據雷達迴波，取得指定地點或使用者目前位置未來一小時的降雨預報。資料每10分鐘更新一次，回傳的資料是一個包含 `rainfallForecast` 鍵的物件，其值為一段描述性文字，例如 `{"rainfallForecast": "臺北市信義區：未來1小時內無降雨"}` 或 `{"rainfallForecast": "無法載入雨量資料，請稍後再試。"}`。',
        parameters: {
          'townshipName': Schema.string(description: '完整的縣市鄉鎮名稱，不含空格，例如 `臺北市信義區`。'),
          'latitude': Schema.number(description: '地標的緯度，例如 25.033。'),
          'longitude': Schema.number(description: '地標的經度，例如 121.564。'),
        },
      );

  List<Tool> get tools => [
        Tool.functionDeclarations([
          getCurrentObservationDecl,
          getUvIndexDecl,
          getAirQualityDecl,
          getWeatherForecastDecl,
          getComprehensiveWeatherReportDecl,
          getOneHourRainfallDecl,
        ]),
      ];

  // --- 2. Tool Execution Handling ---
  Future<Map<String, Object?>> handleFunctionCall(
    String functionName,
    Map<String, Object?> arguments,
  ) async {
    final resolvedLocation = await _resolveLocation(arguments);
    if (resolvedLocation == null) {
      if (arguments.isNotEmpty && 
          (arguments['latitude'] != null || arguments['longitude'] != null || (arguments['townshipName'] as String?)?.isNotEmpty == true)) {
          return {'error': '找不到指定的地點，請確認名稱或經緯度是否正確。'};
      }
      return {'error': '無法取得您目前的位置資訊，請稍後再試。'};
    }

    return switch (functionName) {
      'getCurrentObservation' => _handleGetCurrentObservation(resolvedLocation),
      'getUvIndex' => _handleGetUvIndex(resolvedLocation),
      'getAirQuality' => _handleGetAirQuality(resolvedLocation),
      'getWeatherForecast' => _handleGetWeatherForecast(resolvedLocation),
      'getComprehensiveWeatherReport' => _handleGetComprehensiveReport(resolvedLocation),
      'getOneHourRainfall' => _handleGetOneHourRainfall(resolvedLocation),
      _ => {'error': '不支援的函式呼叫: $functionName'},
    };
  }
  
  Future<Map<String, Object?>> _handleGetCurrentObservation(_ResolvedLocation location) async {
    final data = await _observationRepository.getNearestObservation(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (data?.observations == null) return {'error': '無法取得即時天氣觀測資料。'};
    final details = data!.observations!;
    return {
      'location': data.stationName,
      'temperature': details.temperature,
      'weather': details.weather,
      'humidity': details.humidity,
      'precipitation': details.precipitation,
      'windSpeed': details.windSpeed,
      'windDirection': details.windDirection,
    };
  }

  Future<Map<String, Object?>> _handleGetUvIndex(_ResolvedLocation location) async {
    final data = await _uvIndexRepository.getNearestUVIndex(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (data == null) return {'error': '無法取得紫外線資料。'};
    return {
      'location': data.stationName,
      'uvIndex': data.uvIndex,
      'level': data.level,
    };
  }

  Future<Map<String, Object?>> _handleGetAirQuality(_ResolvedLocation location) async {
    final data = await _airQualityRepository.getNearestAirQuality(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (data == null) return {'error': '無法取得空氣品質資料。'};
    return {
      'location': data.stationName,
      'aqi': data.aqi,
      'status': data.status,
    };
  }

  Future<Map<String, Object?>> _handleGetWeatherForecast(_ResolvedLocation location) async {
    final locationId = location.locationId;
    if (locationId == null) {
      return {'error': '無法解析天氣預報所需的地點ID。'};
    }
    return _fetchForecast(locationId);
  }
  
  Future<Map<String, Object?>> _fetchForecast(String locationId) async {
      final data = await _weatherForecastRepository.getForecastData(locationId);
      if (data == null) return {'error': '無法取得天氣預報資料。'};
      final hourlyList = data.hourlyForecasts.map((f) => {
            'time': f.time.toIso8601String(),
            'temperature': f.temperature,
            'iconCode': f.iconCode,
            'precipitationChance': f.precipitationChance,
          }).toList();
      final dailyList = data.dailyForecasts.map((f) => {
            'dayName': f.dayName,
            'dayTempHigh': f.dayTempHigh,
            'dayTempLow': f.dayTempLow,
            'dayPrecipitationChance': f.dayPrecipitationChance
          }).toList();
      return {
        'hourlyForecasts': hourlyList,
        'dailyForecasts': dailyList,
      };
  }

  Future<Map<String, Object?>> _handleGetComprehensiveReport(_ResolvedLocation location) async {
    final locationData = LocationData(
      name: location.locationId?.replaceAll('_', ' ') ?? '查詢地點',
      latitude: location.latitude,
      longitude: location.longitude,
    );
    await _weatherDataState.fetchDataForSearchedLocation(locationData);
    
    return {
      'location': _weatherDataState.selectedLocationName,
      'temperature': _weatherDataState.temperature,
      'weather': _weatherDataState.condition,
      'uvIndex': _weatherDataState.uvIndex?.uvIndex,
      'aqi': _weatherDataState.airQuality?.aqi,
      'dailyForecasts': _weatherDataState.dailyForecasts.map((f) => {
        'dayName': f.dayName,
        'dayTempHigh': f.dayTempHigh,
        'dayTempLow': f.dayTempLow
      }).toList(),
      'hourlyForecasts': _weatherDataState.hourlyForecasts.map((f) => {
        'time': f.time.toIso8601String(),
        'temperature': f.temperature
      }).toList(),
    };
  }

  Future<Map<String, Object?>> _handleGetOneHourRainfall(_ResolvedLocation location) async {
    try {
      final adminDivision = await _locationService.getAdministrativeDivision(location.latitude, location.longitude);
      final rainfallData = _radarForecastService.rainfallData;

      if (_radarForecastService.isLoading) {
        return {'rainfallForecast': '雨量資料正在下載中，請稍後再試。'};
      }
      if (rainfallData == null) {
        return {'rainfallForecast': '無法載入雨量資料，請稍後再試。'};
      }

      final level = RainfallCalculator.getLevelAt(
        data: rainfallData,
        userLat: location.latitude,
        userLon: location.longitude,
      );
      
      final message = RainfallCalculator.getForecastMessageFromLevel(level, adminDivision);
      return {'rainfallForecast': message};
    } catch (e) {
      return {'rainfallForecast': '無法為該地點計算降雨預報。'};
    }
  }

  // --- 3. Location Resolution Logic (Unchanged) ---
  Future<_ResolvedLocation?> _resolveLocation(Map<String, Object?> arguments) async {
    final lat = arguments['latitude'] as double?;
    final lon = arguments['longitude'] as double?;
    final townshipName = arguments['townshipName'] as String?;

    if (lat != null && lon != null) {
      final adminDivision = await _locationService.getAdministrativeDivision(lat, lon);
      return _ResolvedLocation(
        latitude: lat,
        longitude: lon,
        locationId: adminDivision?.replaceAll(' ', '_'),
      );
    }

    if (townshipName != null && townshipName != 'None' && townshipName != 'none' && townshipName.isNotEmpty) {
      final coords = TaiwanTownshipCoordinate[townshipName];
      if (coords != null) {
        String formattedLocationId = townshipName;
        if (townshipName.length > 3) {
            final county = townshipName.substring(0, 3);
            final town = townshipName.substring(3);
            formattedLocationId = '${county}_$town';
        }
        return _ResolvedLocation(
          latitude: coords['latitude']!,
          longitude: coords['longitude']!,
          locationId: formattedLocationId,
        );
      }
    }

    try {
      final position = await _locationService.getCurrentLocation();
      final adminDivision = await _locationService.getAdministrativeDivision(position.latitude, position.longitude);
      
      if (adminDivision != null) {
        return _ResolvedLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          locationId: adminDivision.replaceAll(' ', '_'),
        );
      }
    } catch (e) {
      // Fall through
    }

    return null;
  }
}
