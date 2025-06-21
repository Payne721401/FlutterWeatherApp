import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Added for SnackBar
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationHelper(this.flutterLocalNotificationsPlugin);

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Replace with your app icon name

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: (id, title, body, payload) async {
      //   // This parameter is deprecated/removed in newer versions.
      //   // Handle notification when app is in foreground (iOS)
      //   debugPrint('onDidReceiveLocalNotification: \$id, \$title, \$body, \$payload');
      // },
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification taps when app is in background/terminated or foreground
        debugPrint('onDidReceiveNotificationResponse: \${notificationResponse.payload}');
      },
    );
  }

  Future<bool> requestNotificationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.notification.status;
    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: const Text('需要通知權限'), // TODO: Localize
            content: const Text('請到設定中開啟通知權限以便接收提醒。'), // TODO: Localize
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('取消'), // TODO: Localize
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                child: const Text('開啟設定'), // TODO: Localize
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings(); // Opens app settings
                },
              ),
            ],
          ),
        );
      }
      return false;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法取得通知權限，請稍後再試。')), // TODO: Localize
        );
      }
      return false;
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
