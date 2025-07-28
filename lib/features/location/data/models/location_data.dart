import 'dart:convert';

class LocationData {
  final String name;
  final double? latitude;
  final double? longitude;

  LocationData({
    required this.name,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocationData &&
        other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}