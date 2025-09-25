import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/background_tasks/evening_forecast_task_handler.dart';
import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';
import 'package:weatherpro/features/weather/data/models/ui_weather_forecast.dart';
import 'package:weatherpro/features/weather/domain/repositories/weather_forecast_repository.dart';
import 'package:weatherpro/services/location_service.dart';
import 'package:weatherpro/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';

// The import for the generated mocks file MUST come after all other imports and declarations.
@GenerateMocks([
  NotificationService,
  LocationService,
  WeatherForecastRepository,
  SharedPreferences,
])
import 'evening_forecast_task_handler_test.mocks.dart';

void main() {
  late MockNotificationService mockNotificationService;
  late MockLocationService mockLocationService;
  late MockWeatherForecastRepository mockWeatherRepo;
  late MockSharedPreferences mockPrefs;
  late EveningForecastTaskHandler taskHandler;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockLocationService = MockLocationService();
    mockWeatherRepo = MockWeatherForecastRepository();
    mockPrefs = MockSharedPreferences();

    taskHandler = EveningForecastTaskHandler.testable(
      notificationService: mockNotificationService,
      locationService: mockLocationService,
      weatherRepo: mockWeatherRepo,
      prefsForTesting: mockPrefs,
    );

    when(mockNotificationService.init()).thenAnswer((_) async => {});
  });

  final testPosition = Position(
    latitude: 25.034, longitude: 121.564, timestamp: DateTime.now(),
    accuracy: 0.0, altitude: 0.0, altitudeAccuracy: 0.0, heading: 0.0,
    headingAccuracy: 0.0, speed: 0.0, speedAccuracy: 0.0,
  );
  const testAdminDivision = '臺北市 信義區';
  const testLocationId = '臺北市_信義區';

  group('EveningForecastTaskHandler Tests', () {

    test('execute should do nothing when disabled', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(false);
      final result = await taskHandler.execute();
      expect(result, isTrue);
      verifyNever(mockLocationService.getCurrentLocation());
      verifyNever(mockWeatherRepo.getForecastData(any));
    });

    test('execute should send notification on success', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(true);
      when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => testPosition);
      when(mockLocationService.getAdministrativeDivision(any, any))
          .thenAnswer((_) async => testAdminDivision);
      
      final tomorrow = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));
      
      final weatherData = UIWeatherDataBundle(
        condition: '晴時多雲',
        conditionIcon: '01d',
        hourlyForecasts: [],
        dailyForecasts: [
          DailyForecast(date: tomorrow, dayName: '明天', dayIconCode: '01d', dayTempHigh: 30.0, dayTempLow: 22.0),
          DailyForecast(date: tomorrow, dayName: '明天', dayIconCode: '02d', dayTempHigh: 28.0, dayTempLow: 24.0),
        ],
      );
      
      when(mockWeatherRepo.getForecastData(testLocationId))
          .thenAnswer((_) async => weatherData);

      final result = await taskHandler.execute();

      expect(result, isTrue);
      verify(mockNotificationService.init()).called(1);
      verify(mockNotificationService.showNotification(
        id: NotificationIds.eveningWeatherForecast,
        title: '明日天氣預報 - $testAdminDivision',
        body: '明日: 22° - 30°C，天氣狀況 晴時多雲。',
        payload: 'evening_forecast_payload',
      )).called(1);
    });

    test('execute should return true if no forecast for tomorrow is available', () async {
        when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
            .thenReturn(true);
        when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => testPosition);
        when(mockLocationService.getAdministrativeDivision(any, any))
            .thenAnswer((_) async => testAdminDivision);

        final twoDaysLater = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 2)));
        
        final weatherData = UIWeatherDataBundle(
          condition: '多雲',
          conditionIcon: '03d',
          hourlyForecasts: [],
          dailyForecasts: [
             DailyForecast(date: twoDaysLater, dayName: '後天', dayIconCode: '03d', dayTempHigh: 30.0, dayTempLow: 22.0),
          ],
        );
        
        when(mockWeatherRepo.getForecastData(testLocationId)).thenAnswer((_) async => weatherData);

        final result = await taskHandler.execute();

        expect(result, isTrue);
        verifyNever(mockNotificationService.showNotification(
            id: anyNamed('id'), title: anyNamed('title'), body: anyNamed('body'), payload: anyNamed('payload')));
    });

     test('execute should return true if location cannot be determined', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(true);
      when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => testPosition);
      when(mockLocationService.getAdministrativeDivision(any, any))
          .thenAnswer((_) async => null);
      
      final result = await taskHandler.execute();

      expect(result, isTrue);
      
      // --- MODIFICATION START ---
      // This essential verification is now restored.
      // It ensures that we exited early BEFORE calling the weather repository.
      verifyNever(mockWeatherRepo.getForecastData(any));
      // --- MODIFICATION END ---
    });

    test('execute should return false when getting location fails', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(true);
      when(mockLocationService.getCurrentLocation()).thenThrow(Exception('Location permission denied'));

      final result = await taskHandler.execute();

      expect(result, isFalse);
    });
  });
}
