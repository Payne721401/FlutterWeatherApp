import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:myapp/features/settings/domain/repositories/notification_settings_repository.dart';
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
  bool _isWeatherAlertEnabled = false;
  bool _isEveningForecastEnabled = false;
  bool _isImminentRainEnabled = false; // State for imminent rain
  TimeOfDay? _doNotDisturbStart;
  TimeOfDay? _doNotDisturbEnd;

  final Map<String, String> _languageDisplayNames = {
    'zh': '繁體中文',
    'en': 'English',
  };

  late final NotificationHelper _notificationHelper;
  final NotificationSettingsRepository _settingsRepo = NotificationSettingsRepository();

  @override
  void initState() {
    super.initState();
    _notificationHelper = NotificationHelper(FlutterLocalNotificationsPlugin());
    _notificationHelper.initNotifications();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    _isWeatherAlertEnabled = await _settingsRepo.isWeatherAlertsEnabled();
    _isEveningForecastEnabled = await _settingsRepo.isEveningForecastEnabled();
    _isImminentRainEnabled = await _settingsRepo.isImminentRainEnabled();

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

  Future<void> _saveGeneralSettings() async {
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

    debugPrint("General settings saved.");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設定已儲存 (${_languageDisplayNames[_selectedLanguage]})'), duration: const Duration(seconds: 1)),
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
      await _notificationHelper.requestNotificationPermission(context);
    } else {
      // If global notifications are turned off, also turn off all individual settings and cancel their tasks.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: const Text('設定'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          LanguageSettingSection(
            selectedLanguage: _selectedLanguage,
            languageDisplayNames: _languageDisplayNames,
            onLanguageChanged: (newLanguage) {
              setState(() {
                _selectedLanguage = newLanguage;
              });
              _saveGeneralSettings();
            },
          ),
          NotificationSettingsSection(
            notificationsEnabled: _notificationsEnabled,
            doNotDisturbStart: _doNotDisturbStart,
            doNotDisturbEnd: _doNotDisturbEnd,
            onNotificationsEnabledChanged: _handleNotificationsEnabledChanged,
            onDoNotDisturbTimeChanged: _handleDoNotDisturbTimeChanged,
          ),
          CupertinoFormSection.insetGrouped(
            header: const Text('個別通知設定'),
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
          const AboutSection(),
        ],
      ),
    );
  }
}
