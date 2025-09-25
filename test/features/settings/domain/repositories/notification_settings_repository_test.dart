// ignore_for_file: prefer_const_constructors

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';
import 'package:weatherpro/features/settings/domain/repositories/workmanager_wrapper.dart';
// import 'package:workmanager/workmanager.dart';


@GenerateMocks([SharedPreferences, WorkmanagerWrapper])
import 'notification_settings_repository_test.mocks.dart';


void main() {
  // --- START OF FINAL & CORRECT MODIFICATION ---
  // This block runs once before all tests in this file.
  setUpAll(() {
    // This "tricks" the test environment into thinking it's running on Android.
    // This is the standard way to test platform-specific code and ensures the
    // `if (_isMobilePlatform)` block in your repository is executed.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  // This block runs after all tests to clean up the platform override.
  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });
  // --- END OF FINAL & CORRECT MODIFICATION ---

  late MockSharedPreferences mockPrefs;
  late MockWorkmanagerWrapper mockWorkmanager;
  late NotificationSettingsRepository repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockWorkmanager = MockWorkmanagerWrapper();
    repository = NotificationSettingsRepository.testable(mockPrefs, mockWorkmanager);
  });

  // YOUR ORIGINAL TEST LOGIC IS 100% PRESERVED BELOW
  group('讀取通知設定 (Getters)', () {
    test('isWeatherAlertsEnabled 應該從 SharedPreferences 讀取正確的 key', () async {
      when(mockPrefs.getBool('weatherAlertsEnabled')).thenReturn(true);
      final result = await repository.isWeatherAlertsEnabled();
      expect(result, isTrue);
      verify(mockPrefs.getBool('weatherAlertsEnabled')).called(1);
    });

    // RESTORED: Your valid test case for the null scenario is preserved.
    test('isEveningForecastEnabled 在 SharedPreferences 中為 null 時應回傳 false', () async {
      when(mockPrefs.getBool('eveningForecastEnabled')).thenReturn(null);
      final result = await repository.isEveningForecastEnabled();
      expect(result, isFalse);
      verify(mockPrefs.getBool('eveningForecastEnabled')).called(1);
    });
  });

  group('更新通知設定 (Setters)', () {
    test('updateWeatherAlertsSetting(true) 應儲存設定並註冊背景任務', () async {
      // Add a 'when' stub for the method we are about to verify.
      when(mockWorkmanager.registerPeriodicTask(any, any, frequency: anyNamed('frequency'), constraints: anyNamed('constraints'))).thenAnswer((_) async {});
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
      
      await repository.updateWeatherAlertsSetting(true);

      verify(mockPrefs.setBool('weatherAlertsEnabled', true)).called(1);
      verify(mockWorkmanager.registerPeriodicTask(
        'weather_alert_task_id', 
        'weatherAlertTask', 
        frequency: Duration(hours: 1),
        constraints: anyNamed('constraints')
      )).called(1);
      verifyNever(mockWorkmanager.cancelByUniqueName(any));
    });

    test('updateWeatherAlertsSetting(false) 應儲存設定並取消背景任務', () async {
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
      // Add a 'when' stub for the method we are about to verify.
      when(mockWorkmanager.cancelByUniqueName(any)).thenAnswer((_) async {});
      
      await repository.updateWeatherAlertsSetting(false);

      verify(mockPrefs.setBool('weatherAlertsEnabled', false)).called(1);
      verify(mockWorkmanager.cancelByUniqueName('weather_alert_task_id')).called(1);
      verifyNever(mockWorkmanager.registerPeriodicTask(any, any, frequency: anyNamed('frequency'), constraints: anyNamed('constraints')));
      
      // PRESERVED: Your correct usage of `""` is maintained.
      verifyNever(mockWorkmanager.registerOneOffTask("", ""));
    });

    test('updateEveningForecastSetting(true) 應註冊正確的晚間預報任務', () async {
       when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
       // Add a 'when' stub for the method we are about to verify.
       when(mockWorkmanager.registerPeriodicTask(any, any, frequency: anyNamed('frequency'), constraints: anyNamed('constraints'))).thenAnswer((_) async {});

      await repository.updateEveningForecastSetting(true);
      
      verify(mockPrefs.setBool('eveningForecastEnabled', true)).called(1);
      verify(mockWorkmanager.registerPeriodicTask(
        'evening_forecast_task_id', 
        'eveningWeatherForecastTask',
        frequency: Duration(days: 1),
        constraints: anyNamed('constraints')
      )).called(1);
    });
  });
}
