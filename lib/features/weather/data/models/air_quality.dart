import 'package:cloud_firestore/cloud_firestore.dart';

class AirQuality {
  final String county;
  final String geohash;
  final String id;
  final double latitude;
  final double longitude;
  final int aqi;
  final String status;
  final String publishTime;
  final String stationId;
  final String stationName;
  final int timestamp;
  final DateTime updatedAt;

  AirQuality({
    required this.county,
    required this.geohash,
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.aqi,
    required this.status,
    required this.publishTime,
    required this.stationId,
    required this.stationName,
    required this.timestamp,
    required this.updatedAt,
  });

  factory AirQuality.fromDocument(Map<String, dynamic> data, String docId) {
    // Safely extract nested location data
    final locationData = data['location'] as Map<String, dynamic>?;
    final latitude = locationData?['latitude'] as double?;
    final longitude = locationData?['longitude'] as double?;

    // Safely extract nested measurements data
    final measurementsData = data['measurements'] as Map<String, dynamic>?;
    final aqi = measurementsData?['aqi'] as int?;
    final status = measurementsData?['status'] as String?;
    final publishTime = data['publishTime'] as String?; // publishTime is top-level based on your new structure

    // **FIXED**: Correctly parse stationId and stationName from the TOP-LEVEL 'data' map
    final stationId = data['stationId'] as String?;
    final stationName = data['stationName'] as String?;

    // The 'timestamp' in your Firestore data is a top-level field
    final rawTimestamp = data['timestamp'];
    final timestamp = rawTimestamp is int
        ? rawTimestamp
        : (rawTimestamp is double ? rawTimestamp.toInt() : (rawTimestamp is String ? int.tryParse(rawTimestamp) : null));

    // Convert Firestore Timestamp to Dart DateTime
    final firestoreUpdatedAt = data['updatedAt'] as Timestamp?;
    final updatedAt = firestoreUpdatedAt?.toDate();

    return AirQuality(
      county: data['county'] as String? ?? '',
      geohash: data['geohash'] as String? ?? '',
      id: docId,
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
      aqi: aqi ?? 0,
      status: status ?? '未知',
      publishTime: publishTime ?? '',
      stationId: stationId ?? '', // Now correctly parsed from top-level data
      stationName: stationName ?? '', // Now correctly parsed from top-level data
      timestamp: timestamp ?? 0,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
