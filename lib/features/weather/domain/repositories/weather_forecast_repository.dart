import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/firestore_service.dart';
import '../../../../models/weather_forecast.dart' as raw;
import '../../data/models/ui_weather_forecast.dart';
import 'dart:developer';
import 'dart:math' hide log;

class UIWeatherDataBundle {
  final String condition;
  final String conditionIcon;
  final double? temperature;
  final double? tempHigh;
  final double? tempLow;
  final List<HourlyForecast> hourlyForecasts;
  final List<DailyForecast> dailyForecasts;

  UIWeatherDataBundle({
    required this.condition,
    required this.conditionIcon,
    this.temperature,
    this.tempHigh,
    this.tempLow,
    required this.hourlyForecasts,
    required this.dailyForecasts,
  });
}

abstract class WeatherForecastRepository {
  Future<UIWeatherDataBundle?> getForecastData(String locationId, {bool forceRefresh = false});
}

class WeatherForecastRepositoryImpl implements WeatherForecastRepository {
  final FirestoreService _firestoreService;
  static const String _logName = 'WeatherForecastRepository';

  WeatherForecastRepositoryImpl(this._firestoreService);

  @override
  Future<UIWeatherDataBundle?> getForecastData(String locationId, {bool forceRefresh = false}) async {
    log('Fetching and transforming raw forecast for: $locationId', name: _logName);
    try {
      final raw.WeatherForecast? rawForecast =
          await _firestoreService.fetchWeatherForecast(locationId, forceRefresh: forceRefresh);

      if (rawForecast == null) {
        log('No raw forecast data found.', name: _logName);
        return null;
      }

      return _transformRawToUIBundle(rawForecast);

    } catch (e, s) {
      log('Error in getForecastData: $e', name: _logName, stackTrace: s);
      return null;
    }
  }

  UIWeatherDataBundle _transformRawToUIBundle(raw.WeatherForecast forecast) {
    final now = DateTime.now();
    final currentRawForecast = forecast.hourlyForecasts.firstWhereOrNull((_) => true);

    final hourlyForecasts = forecast.hourlyForecasts.map((f) => HourlyForecast(
      time: f.startTime,
      iconCode: f.weather,
      temperature: f.temp ?? f.maxTemp ?? 0.0,
      apparentTemperature: f.apparentTemperature,
      precipitationChance: _parseRainProb(f.rainProb),
    )).toList();

    final dailyForecasts = _groupAndMergeWeeklyForecasts(forecast.weeklyForecasts, now);

    final todayUiForecast = dailyForecasts.firstWhereOrNull((df) => df.dayName == '今天') 
                           ?? dailyForecasts.firstOrNull;

    return UIWeatherDataBundle(
      condition: currentRawForecast?.weather ?? '未知',
      conditionIcon: currentRawForecast?.weather ?? '多雲',
      temperature: currentRawForecast?.temp ?? currentRawForecast?.maxTemp,
      tempHigh: todayUiForecast?.dayTempHigh,
      tempLow: todayUiForecast?.dayTempLow,
      hourlyForecasts: hourlyForecasts,
      dailyForecasts: dailyForecasts,
    );
  }

  List<DailyForecast> _groupAndMergeWeeklyForecasts(List<raw.WeeklyForecastItem> weeklyForecasts, DateTime now) {
    if (weeklyForecasts.isEmpty) return [];

    // MODIFIED: Use a robust string-based key for grouping. This is immune to timezone issues.
    final groupedByDate = groupBy(weeklyForecasts, (item) {
      final localTime = item.startTime;
      // Format to "YYYY-MM-DD" string, which is a stable key for grouping.
      return "${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}";
    });

    final mergedForecasts = groupedByDate.entries.map((entry) {
      final itemsForDay = entry.value;
      // Use the first item of the day for date context, as all items in this group share the same local date.
      final referenceItem = itemsForDay.first; 
      final date = DateUtils.dateOnly(referenceItem.startTime);

      final dayItem = itemsForDay.firstWhereOrNull((i) => i.startTime.hour >= 6 && i.startTime.hour < 18);
      final nightItem = itemsForDay.firstWhereOrNull((i) => i.startTime.hour >= 18 || i.startTime.hour < 6);

      final dayTempHigh = itemsForDay.map((e) => e.maxTemp).nonNulls.fold(-999.0, (p, c) => max(p, c));
      final dayTempLow = itemsForDay.map((e) => e.minTemp).nonNulls.fold(999.0, (p, c) => min(p, c));
      final dayMaxApparent = itemsForDay.map((e) => e.maxApparentTemperature).nonNulls.fold(-999.0, (p, c) => max(p, c));
      final dayMinApparent = itemsForDay.map((e) => e.minApparentTemperature).nonNulls.fold(999.0, (p, c) => min(p, c));
      
      final nonNullProbs = itemsForDay.map((e) => _parseRainProb(e.rainProb)).nonNulls.toList();
      final int? maxPrecipitation = nonNullProbs.isEmpty ? null : nonNullProbs.reduce(max);

      String dayName;
      final localNow = DateUtils.dateOnly(now);

      if (DateUtils.isSameDay(date, localNow)) {
        dayName = '今天';
      } else if (DateUtils.isSameDay(date, localNow.add(const Duration(days: 1)))) {
        dayName = '明天';
      } else {
        dayName = DateFormat('E', 'zh_TW').format(date);
      }
      
      return DailyForecast(
        date: date,
        dayName: dayName,
        dayIconCode: dayItem?.weather ?? referenceItem.weather,
        nightIconCode: nightItem?.weather,
        dayTempHigh: dayTempHigh == -999.0 ? 0.0 : dayTempHigh,
        dayTempLow: dayTempLow == 999.0 ? 0.0 : dayTempLow,
        dayMaxApparentTemperature: dayMaxApparent == -999.0 ? null : dayMaxApparent,
        dayMinApparentTemperature: dayMinApparent == 999.0 ? null : dayMinApparent,
        dayPrecipitationChance: maxPrecipitation,
      );
    }).toList();

    mergedForecasts.sort((a, b) => a.date.compareTo(b.date));
    return mergedForecasts;
  }

  int? _parseRainProb(String? rainProbStr) {
    if (rainProbStr == null || rainProbStr == '-99' || !rainProbStr.contains('%')) {
      return null;
    }
    return int.tryParse(rainProbStr.replaceAll('%', '').trim());
  }
}
