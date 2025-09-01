import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:weatherpro/services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';

// --- MODIFICATION START ---
import 'package:flutter/foundation.dart';
import 'dart:developer'; // MODIFIED: Import added
import 'package:flutter/services.dart'; // MODIFIED: Import added
import 'package:firebase_messaging/firebase_messaging.dart'; // MODIFIED: Import added
// 【新增】導入 Crashlytics 套件以進行測試
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:weatherpro/background_tasks/weather_alert_task_handler.dart';
import 'package:weatherpro/background_tasks/evening_forecast_task_handler.dart';
import 'package:weatherpro/background_tasks/imminent_rain_task_handler.dart';
import 'package:badges/badges.dart' as badges;
import 'package:weatherpro/services/announcement_service.dart';
// --- MODIFICATION END ---

import 'package:weatherpro/features/settings/domain/repositories/notification_settings_repository.dart';
import 'package:weatherpro/features/settings/widgets/about_section.dart';
// import 'package:weatherpro/features/settings/widgets/language_setting_section.dart';
import 'package:weatherpro/features/settings/widgets/notification_settings_section.dart';
import 'package:weatherpro/features/settings/utils/notification_helper.dart';
import 'package:weatherpro/features/settings/widgets/announcement_history_dialog.dart'; // MODIFIED: Import added

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isWeatherAlertEnabled = false;
  bool _isEveningForecastEnabled = false;
  bool _isImminentRainEnabled = false;
  TimeOfDay? _doNotDisturbStart;
  TimeOfDay? _doNotDisturbEnd;

  late final NotificationHelper _notificationHelper;
  final NotificationSettingsRepository _settingsRepo = NotificationSettingsRepository();
  PermissionStatus? _locationStatus;

  @override
  void initState() {
    super.initState();
    _notificationHelper = NotificationHelper(FlutterLocalNotificationsPlugin());
    _notificationHelper.initNotifications();
    _loadSettings();
    _checkLocationPermission();
    _checkAndRequestNotificationPermissionOnEntry(); // Request on entry
  }
  
  Future<void> _checkAndRequestNotificationPermissionOnEntry() async {
    final status = await Permission.notification.status;
    if (status.isDenied) { // Only request if user hasn't made a choice yet
      final bool granted = await _notificationHelper.requestNotificationPermission(context);
      
      bool newNotificationState = granted;
      
      await _toggleWeatherAlert(newNotificationState);
      await _toggleEveningForecast(newNotificationState);
      await _toggleImminentRain(newNotificationState);
      
      setState(() {
        _notificationsEnabled = newNotificationState;
      });

      await _saveGeneralSettings();
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    setState(() {
      _locationStatus = status;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    setState(() {
      _locationStatus = status;
    });
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    _isWeatherAlertEnabled = await _settingsRepo.isWeatherAlertsEnabled();
    _isEveningForecastEnabled = await _settingsRepo.isEveningForecastEnabled();
    _isImminentRainEnabled = await _settingsRepo.isImminentRainEnabled();

    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      int? startMinutes = prefs.getInt('doNotDisturbStartMinutes');
      if (startMinutes != null) {
        _doNotDisturbStart = TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);
      }

      int? endMinutes = prefs.getInt('doNotDisturbEndMinutes');
      if (endMinutes != null) {
        _doNotDisturbEnd = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
      }
    });
  }

  Future<void> _saveGeneralSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);

    if (_doNotDisturbStart != null) {
      await prefs.setInt('doNotDisturbStartMinutes', _doNotDisturbStart!.hour * 60 + _doNotDisturbStart!.minute);
    } else {
      await prefs.remove('doNotDisturbStartMinutes');
    }

    if (_doNotDisturbEnd != null) {
      await prefs.setInt('doNotDisturbEndMinutes', _doNotDisturbEnd!.hour * 60 + _doNotDisturbEnd!.minute);
    } else {
      await prefs.remove('doNotDisturbEndMinutes');
    }

    debugPrint("General settings saved.");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設定已儲存'), duration: const Duration(seconds: 1)),
      );
    }
  }
  
  Future<void> _toggleWeatherAlert(bool newValue) async {
    setState(() {
      _isWeatherAlertEnabled = newValue;
    });
    await _settingsRepo.updateWeatherAlertsSetting(newValue);
  }

  Future<void> _toggleEveningForecast(bool newValue) async {
    setState(() {
      _isEveningForecastEnabled = newValue;
    });
    await _settingsRepo.updateEveningForecastSetting(newValue);
  }

  Future<void> _toggleImminentRain(bool newValue) async {
    setState(() {
      _isImminentRainEnabled = newValue;
    });
    await _settingsRepo.updateImminentRainSetting(newValue);
  }

  Future<void> _handleNotificationsEnabledChanged(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      bool granted = await _notificationHelper.requestNotificationPermission(context);
      if (granted) {
        await _toggleWeatherAlert(true);
        await _toggleEveningForecast(true);
        await _toggleImminentRain(true);
      } else {
        setState(() => _notificationsEnabled = false);
        if (_isWeatherAlertEnabled) await _toggleWeatherAlert(false);
        if (_isEveningForecastEnabled) await _toggleEveningForecast(false);
        if (_isImminentRainEnabled) await _toggleImminentRain(false);
      }
    } else {
      if (_isWeatherAlertEnabled) await _toggleWeatherAlert(false);
      if (_isEveningForecastEnabled) await _toggleEveningForecast(false);
      if (_isImminentRainEnabled) await _toggleImminentRain(false);
      
      await _notificationHelper.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已關閉所有通知。')),
        );
      }
    }
    await _saveGeneralSettings();
  }

  void _handleDoNotDisturbTimeChanged(bool isStartTime, TimeOfDay? newTime) {
    setState(() {
      if (isStartTime) {
        _doNotDisturbStart = newTime;
      } else {
        _doNotDisturbEnd = newTime;
      }
    });
    _saveGeneralSettings();
  }

  Future<void> _runAllBackgroundTasks() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚀 正在手動觸發所有背景任務...'), duration: Duration(seconds: 2)),
    );

    final alertResult = await WeatherAlertTaskHandler().execute();
    final eveningResult = await EveningForecastTaskHandler().execute();
    final rainResult = await ImminentRainTaskHandler().execute();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 任務觸發完成！警報:$alertResult, 預報:$eveningResult, 降雨:$rainResult'),
        duration: const Duration(seconds: 4)
      ),
    );
  }

  // MODIFIED: Added method to get and show FCM token
  Future<void> _showFCMToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      log(fcmToken, name: 'FCM Token');

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('FCM Registration Token'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  SelectableText(
                    fcmToken,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('複製'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fcmToken));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FCM Token 已複製到剪貼簿')),
                  );
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('完成'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } else {
      log('Failed to get FCM token.', name: 'FCM');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('取得 FCM Token 失敗')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = context.watch<User?>();
    final announcementService = context.watch<AnnouncementService>();
    const EdgeInsets headerTextPadding = EdgeInsets.only(left: 20.0);

    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44.0),
        child: CupertinoNavigationBar(
          middle: const Text('設定'),
          automaticallyImplyLeading: false,
        ),
      ),
      body: ListView(
        children: [
          CupertinoFormSection.insetGrouped(
            header: Padding(
            padding: headerTextPadding,
            child: const Text('帳號'),
          ),
            children: [
              if (user != null && !user.isAnonymous)
                Column(
                  children: [
                    CupertinoListTile(
                      leading: CircleAvatar(
                        backgroundColor: CupertinoColors.systemGrey3,
                        backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                        child: user.photoURL == null
                            ? SvgPicture.asset(
                                'assets/icons/default_user.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  CupertinoColors.systemGrey,
                                  BlendMode.srcIn,
                                ),
                              )
                            : null,
                      ),
                      title: Text(user.displayName ?? '使用者'),
                      subtitle: Text(user.email ?? '未提供電子郵件'),
                    ),
                    CupertinoListTile(
                      title: const Text('登出'),
                      leading: const Icon(Icons.logout, color: CupertinoColors.destructiveRed),
                      onTap: () async {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
                        }
                      },
                    ),
                  ],
                )
              else
                CupertinoListTile(
                  title: const Text('登入 / 註冊'),
                  leading: const Icon(Icons.person_add_alt_1),
                  onTap: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/splash',
                        (route) => false,
                      );
                    }
                  },
                ),
            ],
          ),

          CupertinoFormSection.insetGrouped(
            header: Padding(
              padding: headerTextPadding,
              child: const Text('訂閱管理'),
            ),
            children: [
              CupertinoListTile(
                title: const Text('我的方案'),
                trailing: Text((user != null && !user.isAnonymous) ? '免費方案' : '訪客模式'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('訂閱管理功能開發中...')),
                  );
                },
              ),
            ],
          ),

          CupertinoFormSection.insetGrouped(
            header: Padding(
              padding: headerTextPadding,
              child: const Text('公告'),
            ),
            children: [
              CupertinoListTile(
                title: const Text('最新公告'),
                onTap: () { // MODIFIED: Changed onTap behavior
                  final announcementService = context.read<AnnouncementService>();
                  announcementService.markAllAsRead();
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => const AnnouncementHistoryDialog(),
                  );
                },
                trailing: badges.Badge(
                  showBadge: announcementService.unreadCount > 0,
                  badgeContent: Text(
                    announcementService.unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  position: badges.BadgePosition.topEnd(top: -12, end: -15),
                  child: const Icon(CupertinoIcons.speaker_2_fill),
                ),
              ),
            ],
          ),

          CupertinoFormSection.insetGrouped(
            header: Padding(
              padding: headerTextPadding,
              child: const Text('定位'),
            ),
            children: [
              CupertinoListTile(
                title: const Text('使用者定位'),
                trailing: Text(
                  _locationStatus?.isGranted ?? false ? '已開啟' : '未開啟',
                ),
                onTap: _locationStatus?.isGranted ?? false
                    ? null
                    : _requestLocationPermission,
              ),
            ],
          ),

          CupertinoFormSection.insetGrouped(
          header: Padding(
            padding: headerTextPadding,
            child: const Text('通知'),
          ),
          children: [
            NotificationSettingsSection(
              notificationsEnabled: _notificationsEnabled,
              doNotDisturbStart: _doNotDisturbStart,
              doNotDisturbEnd: _doNotDisturbEnd,
              onNotificationsEnabledChanged: _handleNotificationsEnabledChanged,
              onDoNotDisturbTimeChanged: _handleDoNotDisturbTimeChanged,
            ),
          ],
        ),
          CupertinoFormSection.insetGrouped(
            header: Padding(
              padding: headerTextPadding,
              child: const Text('個別通知設定'),
            ),
            children: [
              CupertinoListTile(
                title: const Text('天氣警特報通知'),
                trailing: CupertinoSwitch(
                  value: _isWeatherAlertEnabled,
                  onChanged: _notificationsEnabled ? _toggleWeatherAlert : null,
                ),
              ),
              CupertinoListTile(
                title: const Text('每日晚間天氣預報'),
                trailing: CupertinoSwitch(
                  value: _isEveningForecastEnabled,
                  onChanged: _notificationsEnabled ? _toggleEveningForecast : null,
                ),
              ),
              CupertinoListTile(
                title: const Text('即時降雨提醒'),
                trailing: CupertinoSwitch(
                  value: _isImminentRainEnabled,
                  onChanged: _notificationsEnabled ? _toggleImminentRain : null,
                ),
              ),
            ],
          ),

          CupertinoFormSection.insetGrouped(
          header: Padding(
            padding: headerTextPadding,
            child: const Text('關於'),
          ),
          children: [
            const AboutSection(),
          ],
        ),

        if (kDebugMode)
          CupertinoFormSection.insetGrouped(
            header: const Padding(
              padding: headerTextPadding,
              child: Text('開發者測試'),
            ),
            children: [
              CupertinoListTile(
                title: const Text('手動觸發所有背景任務'),
                leading: const Icon(CupertinoIcons.flame_fill, color: Colors.orange),
                onTap: _runAllBackgroundTasks,
              ),
              CupertinoListTile(
                title: const Text('顯示 FCM Token'),
                leading: const Icon(CupertinoIcons.device_laptop, color: Colors.indigo),
                onTap: _showFCMToken,
              ),
              CupertinoListTile(
                title: const Text(
                  '手動觸發 Crashlytics 崩潰',
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
                leading: const Icon(CupertinoIcons.clear_circled_solid, color: CupertinoColors.destructiveRed),
                onTap: () {
                  FirebaseCrashlytics.instance.crash();
                },
              ),

              // --- MODIFICATION START ---
              // TODO: [AI Image Analysis Feature] Re-enable this button to add the entry point for AI image analysis.
              /*
              CupertinoListTile(
                title: const Text('AI 圖片分析'),
                leading: const Icon(CupertinoIcons.camera_viewfinder, color: Colors.cyan),
                onTap: () {
                  // Navigate to the AI analysis screen or show a dialog.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI 圖片分析功能開發中...')),
                  );
                },
              ),
              */
              // --- MODIFICATION END ---
            ],
          ),
        ],
      ),
    );
  }
}
