// lib/services/notification_service.dart

import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

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
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        log('Notification tapped: payload=${response.payload}', name: 'NotificationService');
      },
    );
  }

  // Helper method to check if Do Not Disturb is active
  Future<bool> _isDoNotDisturbActive() async {
    final prefs = await SharedPreferences.getInstance();
    final int? startMinutes = prefs.getInt('doNotDisturbStartMinutes');
    final int? endMinutes = prefs.getInt('doNotDisturbEndMinutes');

    if (startMinutes == null || endMinutes == null) {
      return false; // DND not set up
    }

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= endMinutes) {
      // DND within the same day (e.g., 09:00 - 17:00)
      return currentTimeInMinutes >= startMinutes && currentTimeInMinutes < endMinutes;
    } else {
      // DND crosses midnight (e.g., 23:00 - 07:00)
      return currentTimeInMinutes >= startMinutes || currentTimeInMinutes < endMinutes;
    }
  }

  // Modified: showNotification now respects DND
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (await _isDoNotDisturbActive()) {
      log('Notification (ID: $id) suppressed due to Do Not Disturb period.', name: 'NotificationService');
      return; // Suppress notification
    }

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

  // scheduleDailyNotification logic remains the same; DND check happens at the moment of showing.
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
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
