import 'package:cloud_firestore/cloud_firestore.dart';

class UVIndexData {
  final String geohash;
  final String id;
  final double latitude;
  final double longitude;
  final String stationId;
  final String stationName;
  final int timestamp;
  final DateTime updatedAt;
  final int uvIndex;

  UVIndexData({
    required this.geohash,
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.stationId,
    required this.stationName,
    required this.timestamp,
    required this.updatedAt,
    required this.uvIndex,
  });

  // New getter for UV level
  String get level {
    if (uvIndex <= 2) return '低量級';
    if (uvIndex <= 5) return '中量級';
    if (uvIndex <= 7) return '高量級';
    if (uvIndex <= 10) return '過量級';
    return '危險級';
  }

  factory UVIndexData.fromDocument(Map<String, dynamic> data, String docId) {
    // Safely extract nested location data
    final locationData = data['location'] as Map<String, dynamic>?;
    final latitude = locationData?['latitude'] as double?;
    final longitude = locationData?['longitude'] as double?;

    // Top-level fields
    final geohash = data['geohash'] as String?;
    final stationId = data['stationId'] as String?;
    final stationName = data['stationName'] as String?;
    final uvIndex = data['uvIndex'] as int?;

    // Handle timestamp conversion (can be int or double in Firestore, or null)
    final dynamic rawTimestamp = data['timestamp'];
    final timestamp = rawTimestamp is int
        ? rawTimestamp
        : (rawTimestamp is double ? rawTimestamp.toInt() : (rawTimestamp is String ? int.tryParse(rawTimestamp) : null));

    // Convert Firestore Timestamp to Dart DateTime
    final firestoreUpdatedAt = data['updatedAt'] as Timestamp?;
    final updatedAt = firestoreUpdatedAt?.toDate();

    return UVIndexData(
      geohash: geohash ?? '',
      id: docId,
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
      stationId: stationId ?? '',
      stationName: stationName ?? '',
      timestamp: timestamp ?? 0,
      updatedAt: updatedAt ?? DateTime.now(),
      uvIndex: uvIndex ?? 0,
    );
  }
}
