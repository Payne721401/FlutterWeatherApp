import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/background_tasks/evening_forecast_task_handler.dart';
import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';
import 'package:weatherpro/features/weather/data/models/ui_weather_forecast.dart';
import 'package:weatherpro/features/weather/domain/repositories/weather_forecast_repository.dart';
import 'package:weatherpro/services/notification_service.dart';

@GenerateMocks([
  NotificationService,
  WeatherForecastRepository,
  SharedPreferences,
])
import 'evening_forecast_task_handler_test.mocks.dart';

void main() {
  late MockNotificationService mockNotificationService;
  late MockWeatherForecastRepository mockWeatherRepo;
  late MockSharedPreferences mockPrefs;
  late EveningForecastTaskHandler taskHandler;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockWeatherRepo = MockWeatherForecastRepository();
    mockPrefs = MockSharedPreferences();

    taskHandler = EveningForecastTaskHandler.testable(
      notificationService: mockNotificationService,
      weatherRepo: mockWeatherRepo,
      prefsForTesting: mockPrefs,
    );

    when(mockNotificationService.init()).thenAnswer((_) async => {});
  });

  const testAdminDivision = '臺北市 信義區';
  const testLocationId = '臺北市_信義區';

  group('EveningForecastTaskHandler Tests', () {

    test('execute should do nothing when disabled', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(false);
      final result = await taskHandler.execute();
      expect(result, isTrue);
      verifyNever(mockWeatherRepo.getForecastData(any));
    });

    test('execute should send notification on success', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(true);
      when(mockPrefs.getString('last_known_admin_division'))
          .thenReturn(testAdminDivision);
      
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
        when(mockPrefs.getString('last_known_admin_division'))
            .thenReturn(testAdminDivision);

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

    test('execute should return true when no location is saved', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(true);
      when(mockPrefs.getString('last_known_admin_division')).thenReturn(null);
      
      final result = await taskHandler.execute();

      expect(result, isTrue);
      verifyNever(mockWeatherRepo.getForecastData(any));
    });

    test('execute should return false when weather repository throws', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.eveningForecastEnabledKey))
          .thenReturn(true);
      when(mockPrefs.getString('last_known_admin_division'))
          .thenReturn(testAdminDivision);
      when(mockWeatherRepo.getForecastData(testLocationId)).thenThrow(Exception('Network Error'));

      final result = await taskHandler.execute();

      expect(result, isFalse);
    });
  });
}
