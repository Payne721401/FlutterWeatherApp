import 'package:flutter/cupertino.dart'; // Import Cupertino widgets
import 'package:flutter/material.dart';
// Import shared_preferences for saving settings (Uncomment when ready)
// import 'package:shared_preferences/shared_preferences.dart';

// Ensure you have cupertino_icons in your pubspec.yaml
// dependencies:
//   flutter:
//     sdk: flutter
//   cupertino_icons: ^1.0.2 # Or latest version

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Placeholder state variables
  String _selectedLanguage = 'zh'; // 'zh' for Chinese, 'en' for English
  bool _notificationsEnabled = true;
  TimeOfDay? _doNotDisturbStart;
  TimeOfDay? _doNotDisturbEnd;

  // Map for display names
  final Map<String, String> _languageDisplayNames = {
    'zh': '繁體中文',
    'en': 'English',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load saved settings from SharedPreferences
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _selectedLanguage = prefs.getString('language') ?? 'zh';
    //   _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    //   // Load TimeOfDay if saved
    // });
    // Simulate loading for now
    await Future.delayed(Duration.zero);
  }

  Future<void> _saveSettings() async {
    // TODO: Save settings to SharedPreferences
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString('language', _selectedLanguage);
    // await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    // // Save TimeOfDay if needed
    print("Settings saved (simulated): lang=$_selectedLanguage, notif=$_notificationsEnabled");
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('設定已儲存 (${_languageDisplayNames[_selectedLanguage]})'), duration: const Duration(seconds: 1)),
       );
     }
  }

  void _showLanguagePicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('選擇語言'), // TODO: Localize
        // message: const Text('Your options are '), // Optional message
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: _selectedLanguage == 'zh',
            onPressed: () {
              Navigator.pop(context);
              if (_selectedLanguage != 'zh') {
                setState(() {
                  _selectedLanguage = 'zh';
                });
                _saveSettings(); // Save after changing
                // TODO: Trigger global state change for localization
              }
            },
            child: Text(_languageDisplayNames['zh']!),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: _selectedLanguage == 'en',
            onPressed: () {
              Navigator.pop(context);
               if (_selectedLanguage != 'en') {
                 setState(() {
                   _selectedLanguage = 'en';
                 });
                 _saveSettings(); // Save after changing
                 // TODO: Trigger global state change for localization
               }
            },
            child: Text(_languageDisplayNames['en']!),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('取消'), // TODO: Localize
        ),
      ),
    );
  }

  // --- Time Picker Logic (Example) ---
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
     final TimeOfDay initialTime = isStartTime
          ? _doNotDisturbStart ?? const TimeOfDay(hour: 22, minute: 0)
          : _doNotDisturbEnd ?? const TimeOfDay(hour: 7, minute: 0);

      // Using Material Time Picker for simplicity, replace with CupertinoDatePicker if needed
      final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
           builder: (context, child) {
              // Optional: Apply theme if needed
               return MediaQuery(
                   data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // Example: Force 24h
                   child: child!,
               );
           },
      );

      if (picked != null && picked != (isStartTime ? _doNotDisturbStart : _doNotDisturbEnd)) {
          setState(() {
              if (isStartTime) {
                  _doNotDisturbStart = picked;
              } else {
                  _doNotDisturbEnd = picked;
              }
          });
          _saveSettings(); // Save after changing
      }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
     if (time == null) return '未設定'; // TODO: Localize
     // Use MediaQuery to check 24h format preference if needed
     // final bool alwaysUse24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
     // For simplicity, always use 24h format here
     final hour = time.hour.toString().padLeft(2, '0');
     final minute = time.minute.toString().padLeft(2, '0');
     return '$hour:$minute';
   }


  @override
  Widget build(BuildContext context) {
    // Use CupertinoPageScaffold for iOS-like background and navigation bar
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground, // iOS grouped background color
      navigationBar: const CupertinoNavigationBar(
        middle: Text('設定'), // TODO: Localize
        // Previous page title is automatically handled by CupertinoNavigationBar
      ),
      child: ListView( // Use ListView for scrollable content
        children: [
          // --- Language Section ---
          CupertinoListSection.insetGrouped(
            header: const Text('一般'), // TODO: Localize
            children: <CupertinoListTile>[
              CupertinoListTile(
                title: const Text('語言'), // TODO: Localize
                // Display the selected language name
                additionalInfo: Text(_languageDisplayNames[_selectedLanguage] ?? _selectedLanguage),
                trailing: const CupertinoListTileChevron(),
                onTap: _showLanguagePicker, // Show picker on tap
              ),
            ],
          ),

          // --- Notification Section ---
          CupertinoListSection.insetGrouped(
            header: const Text('通知'), // TODO: Localize
            children: <CupertinoListTile>[
              CupertinoListTile(
                title: const Text('開啟通知'), // TODO: Localize
                // Use CupertinoSwitch for iOS style
                trailing: CupertinoSwitch(
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSettings(); // Save after changing
                  },
                ),
              ),
              // --- Do Not Disturb Sub-section (Example) ---
               CupertinoListTile(
                 title: const Text('勿擾時段'), // TODO: Localize
                 // Display start and end times if set
                  additionalInfo: Text('${_formatTimeOfDay(_doNotDisturbStart)} - ${_formatTimeOfDay(_doNotDisturbEnd)}'),
                  // Could navigate to a dedicated screen or show pickers
                  // For simplicity, tapping row edits start/end times
               ),
               // Optional: Separate tiles for start/end time selection
                CupertinoListTile(
                   title: const Text('  開始時間'), // Indented
                   additionalInfo: Text(_formatTimeOfDay(_doNotDisturbStart)),
                   trailing: const CupertinoListTileChevron(),
                   onTap: () => _selectTime(context, true),
                 ),
                  CupertinoListTile(
                   title: const Text('  結束時間'), // Indented
                   additionalInfo: Text(_formatTimeOfDay(_doNotDisturbEnd)),
                   trailing: const CupertinoListTileChevron(),
                   onTap: () => _selectTime(context, false),
                 ),
            ],
          ),

          // Add more settings sections here using CupertinoListSection.insetGrouped
          // Example: About Section
          CupertinoListSection.insetGrouped(
             header: const Text('關於'), // TODO: Localize
             children: <CupertinoListTile>[
                CupertinoListTile(
                   title: const Text('版本'), // TODO: Localize
                   additionalInfo: const Text('1.0.0'), // TODO: Get from package_info
                   onTap: () { /* Maybe show more details */ },
                 ),
                  CupertinoListTile(
                   title: const Text('開發者資訊'), // TODO: Localize
                   trailing: const CupertinoListTileChevron(),
                   onTap: () { /* Navigate to developer info screen */ },
                 ),
             ],
           ),

        ],
      ),
    );
  }
}
