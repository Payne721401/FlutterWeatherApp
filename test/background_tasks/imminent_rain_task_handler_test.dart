import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/background_tasks/imminent_rain_task_handler.dart';
import 'package:weatherpro/features/radar/data/models/rainfall_data.dart';
import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';
import 'package:weatherpro/services/location_service.dart';
import 'package:weatherpro/services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weatherpro/utils/app_constants.dart';

@GenerateMocks([
  NotificationService,
  LocationService,
  SharedPreferences,
  http.Client,
])
import 'imminent_rain_task_handler_test.mocks.dart';

void main() {
  late MockNotificationService mockNotificationService;
  late MockLocationService mockLocationService;
  late MockSharedPreferences mockPrefs;
  late MockClient mockHttpClient;
  late ImminentRainTaskHandler taskHandler;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockLocationService = MockLocationService();
    mockPrefs = MockSharedPreferences();
    mockHttpClient = MockClient();

    taskHandler = ImminentRainTaskHandler.testable(
      notificationService: mockNotificationService,
      locationService: mockLocationService,
      prefsForTesting: mockPrefs,
      httpClient: mockHttpClient,
    );
     when(mockNotificationService.init()).thenAnswer((_) async => {});
  });
  
  final testPosition = Position(
    latitude: 23.5, 
    longitude: 121.0,
    timestamp: DateTime.now(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
  );
  const testAdminDivision = '臺灣省 南投縣';
  const testRadarUrl = 'http://fake.url/radar.json';

  // --- MODIFICATION START ---
  // This helper function now creates a metadata structure that perfectly matches
  // what RainfallCalculator.getLevelAt expects.
  String createFakeRainfallJson(double value) {
    return json.encode({
      // The keys here now match the keys used in RainfallCalculator.dart
      'metadata': {
        'start_lon': 118.0,
        'start_lat': 21.0,
        'res_lon': 0.0125,
        'res_lat': 0.0125,
        'dim_x': 401,
        'dim_y': 401,
      },
      'rainfall_grid': List.generate(401 * 401, (_) => value),
    });
  }
  // --- MODIFICATION END ---

  group('ImminentRainTaskHandler Tests', () {

    test('execute should do nothing when disabled', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.imminentRainEnabledKey))
          .thenReturn(false);
      final result = await taskHandler.execute();
      expect(result, isTrue);
      verifyNever(mockHttpClient.get(any));
    });

    test('execute should send notification for new significant rainfall', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.imminentRainEnabledKey)).thenReturn(true);
      when(mockPrefs.getString(radarRainfallUrlKey)).thenReturn(testRadarUrl);
      when(mockPrefs.getInt('lastNotifiedRainLevel')).thenReturn(RainfallLevel.noRain.index);
      when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => testPosition);
      when(mockLocationService.getAdministrativeDivision(any, any)).thenAnswer((_) async => testAdminDivision);
      when(mockHttpClient.get(Uri.parse(testRadarUrl)))
          .thenAnswer((_) async => http.Response(createFakeRainfallJson(30.0), 200, headers: {'content-type': 'application/json; charset=utf-8'}));
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);

      final result = await taskHandler.execute();

      expect(result, isTrue);
      verify(mockNotificationService.showNotification(
        id: NotificationIds.imminentRain,
        title: '即時降雨提醒',
        body: anyNamed('body'),
        payload: 'imminent_rain_payload',
      )).called(1);
      verify(mockPrefs.setInt('lastNotifiedRainLevel', RainfallLevel.heavyRain.index)).called(1);
    });

    test('execute should not notify if rain level has not changed', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.imminentRainEnabledKey)).thenReturn(true);
      when(mockPrefs.getString(radarRainfallUrlKey)).thenReturn(testRadarUrl);
      when(mockPrefs.getInt('lastNotifiedRainLevel')).thenReturn(RainfallLevel.moderateRain.index);
      when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => testPosition);
      when(mockLocationService.getAdministrativeDivision(any, any)).thenAnswer((_) async => testAdminDivision);
      when(mockHttpClient.get(Uri.parse(testRadarUrl)))
          .thenAnswer((_) async => http.Response(createFakeRainfallJson(5.0), 200, headers: {'content-type': 'application/json; charset=utf-8'}));

      final result = await taskHandler.execute();

      expect(result, isTrue);
      verifyNever(mockNotificationService.showNotification(id: anyNamed('id'), title: anyNamed('title'), body: anyNamed('body'), payload: anyNamed('payload')));
      verifyNever(mockPrefs.setInt(any, any));
    });

    test('execute should update state to NoRain when rain stops', () async {
       when(mockPrefs.getBool(NotificationSettingsRepository.imminentRainEnabledKey)).thenReturn(true);
      when(mockPrefs.getString(radarRainfallUrlKey)).thenReturn(testRadarUrl);
      when(mockPrefs.getInt('lastNotifiedRainLevel')).thenReturn(RainfallLevel.moderateRain.index);
      when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => testPosition);
      when(mockLocationService.getAdministrativeDivision(any, any)).thenAnswer((_) async => testAdminDivision);
      when(mockHttpClient.get(Uri.parse(testRadarUrl)))
          .thenAnswer((_) async => http.Response(createFakeRainfallJson(0.0), 200, headers: {'content-type': 'application/json; charset=utf-8'}));
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);

      final result = await taskHandler.execute();

      expect(result, isTrue);
      verifyNever(mockNotificationService.showNotification(id: anyNamed('id'), title: anyNamed('title'), body: anyNamed('body'), payload: anyNamed('payload')));
      verify(mockPrefs.setInt('lastNotifiedRainLevel', RainfallLevel.noRain.index)).called(1);
    });

    test('execute should return false on network failure', () async {
      when(mockPrefs.getBool(NotificationSettingsRepository.imminentRainEnabledKey)).thenReturn(true);
      when(mockPrefs.getString(radarRainfallUrlKey)).thenReturn(testRadarUrl);
      when(mockLocationService.getCurrentLocation()).thenAnswer((_) async => testPosition);
      when(mockLocationService.getAdministrativeDivision(any, any)).thenAnswer((_) async => testAdminDivision);
      when(mockHttpClient.get(Uri.parse(testRadarUrl)))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await taskHandler.execute();

      expect(result, isFalse);
    });
  });
}
