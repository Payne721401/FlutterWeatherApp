import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:weatherpro/features/settings/utils/time_format_util.dart'; // Adjust import path

class NotificationSettingsSection extends StatelessWidget {
  final bool notificationsEnabled;
  final TimeOfDay? doNotDisturbStart;
  final TimeOfDay? doNotDisturbEnd;
  final ValueChanged<bool> onNotificationsEnabledChanged;
  final Function(bool isStartTime, TimeOfDay? newTime) onDoNotDisturbTimeChanged;

  const NotificationSettingsSection({
    super.key,
    required this.notificationsEnabled,
    required this.doNotDisturbStart,
    required this.doNotDisturbEnd,
    required this.onNotificationsEnabledChanged,
    required this.onDoNotDisturbTimeChanged,
  });

  // Generic time picker function
  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay? initialTime) async {
    final DateTime now = DateTime.now();
    DateTime tempPickedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime?.hour ?? 0,
      initialTime?.minute ?? 0,
    );

    final result = await showCupertinoModalPopup<TimeOfDay?>( // Changed return type to TimeOfDay?
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  onPressed: () {
                    // Pop with the temporarily selected time
                    Navigator.pop(context, TimeOfDay.fromDateTime(tempPickedDateTime));
                  },
                  child: const Text('完成', style: TextStyle(fontWeight: FontWeight.bold)), // TODO: Localize
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: tempPickedDateTime, // Use the initially passed or default time
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    // Update temporary selected time as user scrolls
                    tempPickedDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result; // Return the result from Navigator.pop
  }

  // Handles the sequential picking of start and end times for Do Not Disturb
  Future<void> _handleDoNotDisturbTap(BuildContext context) async {
    // Select start time
    final TimeOfDay? pickedStartTime = await _selectTime(
      context,
      doNotDisturbStart ?? const TimeOfDay(hour: 22, minute: 0), // Default start time
    );

    // If a start time was selected, proceed to select end time
    if (pickedStartTime != null) {
      onDoNotDisturbTimeChanged(true, pickedStartTime); // Update start time

      if (!context.mounted) return;

      final TimeOfDay? pickedEndTime = await _selectTime(
        context,
        doNotDisturbEnd ?? const TimeOfDay(hour: 7, minute: 0), // Default end time
      );

      if (pickedEndTime != null) {
        onDoNotDisturbTimeChanged(false, pickedEndTime); // Update end time
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <CupertinoListTile>[
        CupertinoListTile(
          title: const Text('開啟通知'), // TODO: Localize
          trailing: CupertinoSwitch(
            value: notificationsEnabled,
            onChanged: onNotificationsEnabledChanged,
          ),
        ),
        // Consolidated Do Not Disturb setting
        CupertinoListTile(
          title: const Text('勿擾時段'), // TODO: Localize
          additionalInfo: Text('${TimeFormatUtil.formatTimeOfDay(doNotDisturbStart)} - ${TimeFormatUtil.formatTimeOfDay(doNotDisturbEnd)}'),
          trailing: const CupertinoListTileChevron(), // Add chevron to indicate tappable
          onTap: () => _handleDoNotDisturbTap(context), // Tap to set both times
        ),
      ],
    );
  }
}
