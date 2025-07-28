// lib/services/notification_service.dart

import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Defines unique IDs for different notification types
class NotificationIds {
  static const int morningClothingAdvice = 100;
  static const int eveningWeatherForecast = 101; // 明日天氣通知
  static const int imminentRain = 102; // 即將降雨通知
  static const int weatherAlert = 103; // 天氣警特報通知
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize time zones for accurate scheduling
    tz.initializeTimeZones();

    // Android specific initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS specific initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // General initialization settings for all platforms
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        log('Notification tapped: payload=${response.payload}', name: 'NotificationService');
      },
    );
  }

  // Method to display a simple, immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
          android: AndroidNotificationDetails(
            'weather_app_channel',
            '天氣通知',
            channelDescription: '提供天氣相關通知',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: DarwinNotificationDetails()
        );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Method to schedule a notification at a specific time daily
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    String channelId = 'daily_weather_channel',
    String channelName = '每日天氣提醒',
    String channelDescription = '每日定時提供天氣相關提醒',
    Importance importance = Importance.low,
    Priority priority = Priority.low,
  }) async {
    await _flutterLocalNotificationsPlugin.cancel(id);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: channelDescription,
              importance: importance,
              priority: priority,
            ),
            iOS: const DarwinNotificationDetails(),
        );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // CORRECTED: The parameter is part of the platform-specific details, not a top-level parameter.
      // We will rely on the default interpretation for now which works for most cases.
      // For more complex iOS scheduling, uiLocalNotificationDateInterpretation would be set inside DarwinNotificationDetails.
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // Method to cancel a specific notification by its ID
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
