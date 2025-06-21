import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:myapp/features/settings/widgets/about_section.dart';
import 'package:myapp/features/settings/widgets/language_setting_section.dart';
import 'package:myapp/features/settings/widgets/notification_settings_section.dart';
import 'package:myapp/features/settings/utils/notification_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'zh';
  bool _notificationsEnabled = true;
  TimeOfDay? _doNotDisturbStart;
  TimeOfDay? _doNotDisturbEnd;

  final Map<String, String> _languageDisplayNames = {
    'zh': '繁體中文',
    'en': 'English',
  };

  late final NotificationHelper _notificationHelper;

  @override
  void initState() {
    super.initState();
    // Initialize the NotificationHelper with an instance of FlutterLocalNotificationsPlugin
    _notificationHelper = NotificationHelper(FlutterLocalNotificationsPlugin());
    _notificationHelper.initNotifications(); // Initialize notification plugin
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'zh';
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

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _selectedLanguage);
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

    debugPrint("Settings saved: lang=\$_selectedLanguage, notif=\$_notificationsEnabled, DND Start=\$_doNotDisturbStart, DND End=\$_doNotDisturbEnd");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設定已儲存 (${_languageDisplayNames[_selectedLanguage]})'), duration: const Duration(seconds: 1)),
      );
    }
  }

  // This function will be passed down to NotificationSettingsSection
  Future<void> _handleNotificationsEnabledChanged(bool value) async {
    if (value) {
      bool granted = await _notificationHelper.requestNotificationPermission(context);
      if (granted) {
        setState(() {
          _notificationsEnabled = true;
        });
        _saveSettings();
      } else {
        // If permission not granted, revert switch state
        setState(() {
          _notificationsEnabled = false;
        });
      }
    } else {
      setState(() {
        _notificationsEnabled = false;
      });
      _saveSettings();
      await _notificationHelper.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已關閉所有通知。')), // TODO: Localize
        );
      }
    }
  }

  // This function will be passed down to NotificationSettingsSection for DND times
  void _handleDoNotDisturbTimeChanged(bool isStartTime, TimeOfDay? newTime) {
    setState(() {
      if (isStartTime) {
        _doNotDisturbStart = newTime;
      } else {
        _doNotDisturbEnd = newTime;
      }
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('設定'), // TODO: Localize
      ),
      child: ListView(
        children: [
          LanguageSettingSection(
            selectedLanguage: _selectedLanguage,
            languageDisplayNames: _languageDisplayNames,
            onLanguageChanged: (newLanguage) {
              setState(() {
                _selectedLanguage = newLanguage;
              });
              _saveSettings();
              // TODO: Trigger global state change for localization
            },
          ),
          NotificationSettingsSection(
            notificationsEnabled: _notificationsEnabled,
            doNotDisturbStart: _doNotDisturbStart,
            doNotDisturbEnd: _doNotDisturbEnd,
            onNotificationsEnabledChanged: _handleNotificationsEnabledChanged,
            onDoNotDisturbTimeChanged: _handleDoNotDisturbTimeChanged,
          ),
          const AboutSection(),
        ],
      ),
    );
  }
}
