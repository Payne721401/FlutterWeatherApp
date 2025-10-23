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
      // Given: The last notified alert timestamp is older than the new alert's timestamp
      final olderTimestamp = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      when(mockPrefs.getInt('lastNotifiedAlertTimestamp')).thenReturn(olderTimestamp);
      
      final newAlert = WeatherAlert(
        title: 'New Alert Title',
        description: 'This is a new alert.',
        issuedTime: DateTime.now(),
        authorName: 'CWA',
      );

      when(mockAlertRepo.fetchAlerts()).thenAnswer((_) async => [newAlert]);
      // Given: SharedPreferences setInt returns successfully
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);

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
      // Then: The new alert timestamp is saved to SharedPreferences
      verify(mockPrefs.setInt('lastNotifiedAlertTimestamp', newAlert.issuedTime.millisecondsSinceEpoch)).called(1);
    });

    // Test Case 3: No new alert found, no notification should be sent
    test('execute should not send a notification if the alert is not new', () async {
      // Given: Alerts are enabled
      when(mockPrefs.getBool(NotificationSettingsRepository.weatherAlertsEnabledKey))
          .thenReturn(true);
      // Given: The last notified alert timestamp is the same as the fetched one
      final sameTime = DateTime.now();
      when(mockPrefs.getInt('lastNotifiedAlertTimestamp')).thenReturn(sameTime.millisecondsSinceEpoch);

      final oldAlert = WeatherAlert(
        title: 'Old Alert Title',
        description: 'This is the same alert.',
        issuedTime: sameTime, // Same timestamp as last notified
        authorName: 'CWA',
      );
      
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
      // Then: setInt is not called as the timestamp is not newer
      verifyNever(mockPrefs.setInt(any, any));
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
