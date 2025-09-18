import 'dart:developer';

import 'package:flutter/material.dart';

// Represents sunrise and sunset data, now in its own file.
class SunriseSunsetData {
  final TimeOfDay sunriseTime;
  final TimeOfDay sunsetTime;

  SunriseSunsetData({
    required this.sunriseTime,
    required this.sunsetTime,
  });

  factory SunriseSunsetData.fromMap(Map<String, dynamic> map) {
    // Helper to parse time strings like "05:30" into TimeOfDay
    TimeOfDay parseTime(String timeString) {
      try {
        final parts = timeString.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        // Return a default value or handle the error appropriately
        log('Error parsing time string "$timeString": $e');
        return const TimeOfDay(hour: 0, minute: 0);
      }
    }

    return SunriseSunsetData(
      sunriseTime: parseTime(map['sunriseTime'] as String? ?? '00:00'),
      sunsetTime: parseTime(map['sunsetTime'] as String? ?? '00:00'),
    );
  }
}
