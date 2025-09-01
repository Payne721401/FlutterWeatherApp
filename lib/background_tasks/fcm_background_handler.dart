import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/announcement.dart';
import '../services/notification_service.dart';
import '../firebase_options.dart';

const _kAnnouncementsKey = 'announcements_storage_key';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize bindings.
  final token = RootIsolateToken.instance;
  if (token == null) {
    log('[Background Handler] Error: Could not get RootIsolateToken.', name: 'FCM');
    return;
  }
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notification = message.notification;
  final data = message.data;

  log('[Background Handler] Received message: ${message.messageId}', name: 'FCM');

  // Exit if there is nothing to process.
  if (notification == null && data.isEmpty) {
    log('[Background Handler] Received an empty message. Skipping.', name: 'FCM');
    return;
  }

  try {
    // 2. Smartly create a complete announcement data object.
    // Priority: data payload > notification payload > generated value.
    final announcement = Announcement(
      id: data['id']?.toString() ?? 'noti_${DateTime.now().millisecondsSinceEpoch}',
      title: data['title']?.toString() ?? notification?.title ?? '新公告',
      content: data['content']?.toString() ?? notification?.body ?? '點擊查看詳情',
      timestamp: (data['timestamp'] != null)
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      isRead: false,
    );

    // 3. Perform raw SharedPreferences operations to save the announcement.
    final prefs = await SharedPreferences.getInstance();
    final List<String> announcementsJson = prefs.getStringList(_kAnnouncementsKey) ?? [];
    
    final bool alreadyExists = announcementsJson.any((json) {
      try {
        return jsonDecode(json)['id'] == announcement.id;
      } catch (_) {
        return false;
      }
    });

    if (alreadyExists) {
      log('[Background Handler] Announcement ${announcement.id} already exists. Skipping save.', name: 'FCM');
    } else {
      announcementsJson.insert(0, announcement.toJson());
      await prefs.setStringList(_kAnnouncementsKey, announcementsJson);
      log('[Background Handler] Announcement ${announcement.id} saved successfully.', name: 'FCM');
    }

    // 4. Display a local notification to the user.
    final notificationService = NotificationService();
    await notificationService.init();

    await notificationService.showNotification(
      id: NotificationIds.announcement,
      title: announcement.title,
      body: announcement.content,
      payload: 'announcement_payload',
    );
    log('[Background Handler] Local notification shown.', name: 'FCM');

  } catch (e, s) {
    log('[Background Handler] CRITICAL ERROR: $e', name: 'FCM', error: e, stackTrace: s);
  }
}
