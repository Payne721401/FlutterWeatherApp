import 'package:flutter/material.dart';

class TimeFormatUtil {
  static String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '未設定'; // TODO: Localize
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '\$hour:\$minute';
  }
}
