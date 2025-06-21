import 'package:flutter/material.dart'; // For TimeOfDay, DateUtils
import '../../../../services/firestore_service.dart';
import '../../../../models/weather_forecast.dart';
import '../../data/models/weather_data.dart'; // Contains WeatherInfo, HourlyForecast, DailyForecast
import 'package:intl/intl.dart'; // For date formatting
import 'dart:developer'; // Import for log

abstract class WeatherRepository {
  Future<WeatherInfo?> getWeatherDataForLocation(String locationId, {bool forceRefresh = false, required CacheType type});
}

class WeatherRepositoryImpl implements WeatherRepository {
  final FirestoreService _firestoreService;
  static const String _logName = 'WeatherRepository';

  WeatherRepositoryImpl(this._firestoreService);

  @override
  Future<WeatherInfo?> getWeatherDataForLocation(String locationId, {bool forceRefresh = false, required CacheType type}) async {
    log('Fetching weather data for location: $locationId (CacheType: $type)', name: _logName);
    final WeatherForecast? firebaseForecast = await _firestoreService.fetchWeatherForecastByLocation(locationId, forceRefresh: forceRefresh, type: type);

    if (firebaseForecast == null) {
      log('No Firebase data found for $locationId (CacheType: $type).', name: _logName);
      return null; // No data found for this location
    }

    log('Successfully fetched Firebase data for $locationId (CacheType: $type).', name: _logName);
    log('Firebase Forecast Raw Data (ID): ${firebaseForecast.id}', name: _logName);
    log('Firebase Forecast Raw Data (County Name): ${firebaseForecast.countyName}', name: _logName);
    log('Firebase Forecast Raw Data (Updated At): ${firebaseForecast.updatedAt}', name: _logName);
    // The 'location' property is non-nullable in WeatherForecast model, so direct access is fine here.
    log('Firebase Forecast Raw Data (Location Latitude): ${firebaseForecast.location.latitude}', name: _logName); 
    log('Firebase Forecast Raw Data (Location Longitude): ${firebaseForecast.location.longitude}', name: _logName); 
    log('Firebase Forecast Raw Data (Location Town Name): ${firebaseForecast.location.townName}', name: _logName); 
    log('Firebase Forecast Raw Data (Location Timestamp): ${firebaseForecast.location.timestamp}', name: _logName); 

    // Convert Firebase models to UI models (WeatherInfo, HourlyForecast, DailyForecast)
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    // Current Conditions: Take the most relevant forecast (e.g., the first one)
    final currentForecast = firebaseForecast.forecasts.isNotEmpty ? firebaseForecast.forecasts.first : null;

    // Log details of the current forecast (if available)
    if (currentForecast != null) {
      log('Current Forecast Details:', name: _logName);
      log('  Temp: ${currentForecast.temp}', name: _logName);
      log('  Comfort: ${currentForecast.comfort}', name: _logName);
      log('  EndTime: ${currentForecast.endTime}', name: _logName);
      log('  Humidity: ${currentForecast.humidity}', name: _logName);
      log('  MaxTemp: ${currentForecast.maxTemp}', name: _logName);
      log('  MinTemp: ${currentForecast.minTemp}', name: _logName);
      log('  RainProb: ${currentForecast.rainProb}', name: _logName);
      log('  StartTime: ${currentForecast.startTime}', name: _logName);
      log('  Timestamp: ${currentForecast.timestamp}', name: _logName);
      log('  Weather: ${currentForecast.weather}', name: _logName);
      log('  WindDirection: ${currentForecast.windDirection}', name: _logName);
      log('  WindSpeed: ${currentForecast.windSpeed}', name: _logName);
    }

    // Hourly Forecasts: Map from Firebase Forecasts
    final List<HourlyForecast> hourlyForecasts = firebaseForecast.forecasts.map((f) {
      log('Mapping Hourly Forecast Item:', name: _logName);
      log('  Time: ${f.startTime}', name: _logName);
      log('  Weather: ${f.weather}', name: _logName);
      log('  Temp: ${f.temp}', name: _logName);
      log('  MaxTemp: ${f.maxTemp}', name: _logName);
      log('  MinTemp: ${f.minTemp}', name: _logName);
      log('  RainProb: ${f.rainProb}', name: _logName);
      return HourlyForecast(
        time: f.startTime,
        iconCode: _mapWeatherConditionToIcon(f.weather ?? ''), // Null-safe string for icon mapping
        temperature: f.temp ?? f.maxTemp ?? 0.0, // Use ?? to provide default if temp or maxTemp is null
        precipitationChance: int.tryParse(f.rainProb?.replaceAll('%', '') ?? '0') ?? 0,
      );
    }).toList();

    // Daily Forecasts: Map from WeeklyForecastItems
    final List<DailyForecast> dailyForecasts = firebaseForecast.weeklyForecast?.forecasts.map((wf) {
      log('Mapping Daily Forecast Item (Weekly):', name: _logName);
      log('  Comfort: ${wf.comfort}', name: _logName);
      log('  EndTime: ${wf.endTime}', name: _logName);
      log('  Humidity: ${wf.humidity}', name: _logName);
      log('  MaxTemp: ${wf.maxTemp}', name: _logName);
      log('  MinTemp: ${wf.minTemp}', name: _logName);
      log('  RainProb: ${wf.rainProb}', name: _logName);
      log('  StartTime: ${wf.startTime}', name: _logName);
      log('  Timestamp: ${wf.timestamp}', name: _logName);
      log('  Weather: ${wf.weather}', name: _logName);
      log('  WindDirection: ${wf.windDirection}', name: _logName);
      log('  WindSpeed: ${wf.windSpeed}', name: _logName);

      final forecastDate = wf.startTime;
      final String dayName;
      if (DateUtils.isSameDay(forecastDate, now)) {
         dayName = '今天';
      } else if (DateUtils.isSameDay(forecastDate, now.add(const Duration(days: 1)))) {
         dayName = '明天';
      } else {
         dayName = DateFormat('EEEE', 'zh_TW').format(forecastDate);
      }

      return DailyForecast(
        date: forecastDate,
        dayName: dayName,
        dayIconCode: _mapWeatherConditionToIcon(wf.weather ?? ''), // Null-safe string for icon mapping
        dayPrecipitationChance: int.tryParse(wf.rainProb?.replaceAll('%', '') ?? '0') ?? 0,
        dayTempHigh: wf.maxTemp ?? 0.0, // MODIFIED: Use ?? 0.0
        dayTempLow: wf.minTemp ?? 0.0, // MODIFIED: Use ?? 0.0
        nightIconCode: _mapWeatherConditionToIcon(wf.weather ?? ''), // Null-safe string for icon mapping
        nightPrecipitationChance: int.tryParse(wf.rainProb?.replaceAll('%', '') ?? '0') ?? 0,
        nightTempHigh: wf.maxTemp ?? 0.0, // MODIFIED: Use ?? 0.0
        nightTempLow: wf.minTemp ?? 0.0, // MODIFIED: Use ?? 0.0
      );
    }).toList() ?? [];

    // Construct locationName safely
    final String effectiveCountyName = firebaseForecast.countyName ?? ''; 
    final String effectiveTownName = firebaseForecast.location.townName ?? ''; // Location is non-nullable now
    String finalLocationName = effectiveCountyName;
    if (effectiveTownName.isNotEmpty) {
      finalLocationName += ' ' + effectiveTownName;
    }

    return WeatherInfo(
      locationName: finalLocationName,
      lastUpdated: firebaseForecast.updatedAt,
      condition: currentForecast?.weather ?? '未知',
      iconCode: _mapWeatherConditionToIcon(currentForecast?.weather ?? ''),
      temperature: currentForecast?.temp ?? currentForecast?.maxTemp ?? 0.0, // Use ?? to provide default if temp or maxTemp is null
      feelsLike: currentForecast?.temp ?? currentForecast?.maxTemp ?? 0.0, // Placeholder, adjust if 'feelsLike' exists
      tempHigh: currentForecast?.maxTemp ?? 0.0, // MODIFIED: Use ?? 0.0
      tempLow: currentForecast?.minTemp ?? 0.0, // MODIFIED: Use ?? 0.0
      tempYesterdayHigh: 0.0, // Not available from Firebase data
      tempYesterdayLow: 0.0, // Not available from Firebase data
      windSpeed: currentForecast?.windSpeed ?? 0.0, // MODIFIED: Use ?? 0.0
      humidity: int.tryParse(currentForecast?.humidity?.replaceAll('%', '') ?? '0') ?? 0, 
      precipitationChance: int.tryParse(currentForecast?.rainProb?.replaceAll('%', '') ?? '0') ?? 0, 
      aqi: 0, // Not available from Firebase data
      aqiLevel: '未知', // Not available
      uvIndex: 0, // Not available
      uvLevel: '未知', // Not available
      clothingAdvice: currentForecast?.comfort ?? '未知',
      clothingIndexValue: 0, // Needs specific logic or data
      umbrellaAdvice: (int.tryParse(currentForecast?.rainProb?.replaceAll('%', '') ?? '0') ?? 0) > 30 ? '建議攜帶雨具' : '無需攜帶雨具', 
      umbrellaIndexValue: (int.tryParse(currentForecast?.rainProb?.replaceAll('%', '') ?? '0') ?? 0) > 30 ? 1 : 0, // 0: no, 1: yes
      activityAdvice: '適宜', // Needs specific logic or data
      activityIndexValue: 0, // Needs specific logic or data
      aiSummary: '此為來自 Firebase 的天氣預報資料摘要。請根據實際資料填充此處。',
      sunrise: const TimeOfDay(hour: 0, minute: 0), // Not directly available, estimate if needed
      sunset: const TimeOfDay(hour: 0, minute: 0), // Not directly available, estimate if needed
      hourlyForecasts: hourlyForecasts,
      dailyForecasts: dailyForecasts,
    );
  }

  // Helper function to map weather condition strings to icon codes
  String _mapWeatherConditionToIcon(String weatherCondition) {
    weatherCondition = weatherCondition.toLowerCase();
    if (weatherCondition.contains('晴')) {
      return '01d'; // Sunny
    } else if (weatherCondition.contains('多雲') || weatherCondition.contains('陰')) {
      return '04d'; // Cloudy
    } else if (weatherCondition.contains('短暫陣雨') || weatherCondition.contains('雷雨')) {
      return '10d'; // Rain
    } else {
      return '01d'; // Default icon
    }
  }
}
