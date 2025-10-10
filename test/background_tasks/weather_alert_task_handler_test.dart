import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/background_tasks/weather_alert_task_handler.dart';
import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';
import 'package:weatherpro/features/weather/data/models/weather_alert.dart';
import 'package:weatherpro/features/weather/domain/repositories/alert_repository.dart';
import 'package:weatherpro/services/notification_service.dart';

// Generate mocks using build_runner: flutter pub run build_runner build
@GenerateMocks([NotificationService, AlertRepository, SharedPreferences])
import 'weather_alert_task_handler_test.mocks.dart';

void main() {
  // 1. Declare variables for the mocks and the class under test
  late MockNotificationService mockNotificationService;
  late MockAlertRepository mockAlertRepo;
  late MockSharedPreferences mockPrefs;
  late WeatherAlertTaskHandler taskHandler;

  // 2. Set up mocks before each test
  setUp(() {
    mockNotificationService = MockNotificationService();
    mockAlertRepo = MockAlertRepository();
    mockPrefs = MockSharedPreferences();
    
    // Initialize the task handler with mocked dependencies
    taskHandler = WeatherAlertTaskHandler.testable(
      notificationService: mockNotificationService,
      alertRepo: mockAlertRepo,
      prefsForTesting: mockPrefs,
    );

    // Default behavior for init() - can be overridden in specific tests
    when(mockNotificationService.init()).thenAnswer((_) async => {});
  });

  group('WeatherAlertTaskHandler Tests', () {

    // Test Case 1: Feature is disabled by the user
    test('execute should return true and do nothing when alerts are disabled', () async {
      // Given: SharedPreferences returns false for the enabled key
      when(mockPrefs.getBool(NotificationSettingsRepository.weatherAlertsEnabledKey))
          .thenReturn(false);

      // When: The task is executed
      final result = await taskHandler.execute();

      // Then: The result is true (successful no-op) and no other services are called
      expect(result, isTrue);
      verifyNever(mockNotificationService.init());
      verifyNever(mockAlertRepo.fetchAlerts());
      verifyNever(mockNotificationService.showNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        payload: anyNamed('payload'),
      ));
    });

    // Test Case 2: Happy path - A new alert is found and a notification should be sent
    test('execute should send a notification for a new weather alert', () async {
      // Given: Alerts are enabled
      when(mockPrefs.getBool(NotificationSettingsRepository.weatherAlertsEnabledKey))
          .thenReturn(true);
      // Given: The last notified alert title is different from the new one
      when(mockPrefs.getString('lastNotifiedAlertTitle')).thenReturn('Old Alert Title');
      
      // *** MODIFICATION START ***
      // Correctly instantiate WeatherAlert with the right parameters
      final newAlert = WeatherAlert(
        title: 'New Alert Title',
        description: 'This is a new alert.',
        issuedTime: DateTime.now(),
        authorName: 'CWA',
      );
      // *** MODIFICATION END ***

      when(mockAlertRepo.fetchAlerts()).thenAnswer((_) async => [newAlert]);
      // Given: SharedPreferences setString returns successfully
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // When: The task is executed
      final result = await taskHandler.execute();

      // Then: The result is true
      expect(result, isTrue);
      // Then: NotificationService is initialized
      verify(mockNotificationService.init()).called(1);
      // Then: A notification is shown with the correct details
      verify(mockNotificationService.showNotification(
        id: NotificationIds.weatherAlert,
        title: '天氣特報：${newAlert.title}',
        body: newAlert.description,
        payload: 'weather_alert_payload',
      )).called(1);
      // Then: The new alert title is saved to SharedPreferences
      verify(mockPrefs.setString('lastNotifiedAlertTitle', newAlert.title)).called(1);
    });

    // Test Case 3: No new alert found, no notification should be sent
    test('execute should not send a notification if the alert is not new', () async {
      // Given: Alerts are enabled
      when(mockPrefs.getBool(NotificationSettingsRepository.weatherAlertsEnabledKey))
          .thenReturn(true);
      // Given: The last notified alert title is the same as the fetched one
      const sameAlertTitle = 'Same Alert Title';
      when(mockPrefs.getString('lastNotifiedAlertTitle')).thenReturn(sameAlertTitle);

      // *** MODIFICATION START ***
      final oldAlert = WeatherAlert(
        title: sameAlertTitle,
        description: 'This is the same alert.',
        issuedTime: DateTime.now(),
        authorName: 'CWA',
      );
      // *** MODIFICATION END ***
      
      when(mockAlertRepo.fetchAlerts()).thenAnswer((_) async => [oldAlert]);

      // When: The task is executed
      final result = await taskHandler.execute();

      // Then: The result is true
      expect(result, isTrue);
      // Then: No notification is sent
      verifyNever(mockNotificationService.showNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        payload: anyNamed('payload'),
      ));
      // Then: setString is not called as the title is the same
      verifyNever(mockPrefs.setString(any, any));
    });

    // Test Case 4: External service fails
    test('execute should return false when the alert repository throws an error', () async {
      // Given: Alerts are enabled
      when(mockPrefs.getBool(NotificationSettingsRepository.weatherAlertsEnabledKey))
          .thenReturn(true);
      // Given: The alert repository fails
      when(mockAlertRepo.fetchAlerts()).thenThrow(Exception('Network Error'));

      // When: The task is executed
      final result = await taskHandler.execute();

      // Then: The result is false, indicating a failure
      expect(result, isFalse);
      // Then: No notification is sent
      verifyNever(mockNotificationService.showNotification(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        payload: anyNamed('payload'),
      ));
    });
  });
}
