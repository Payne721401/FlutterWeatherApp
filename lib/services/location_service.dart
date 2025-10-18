import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer';

class LocationService {
  static const String _logName = 'LocationService';

  Future<Position> getCurrentLocation() async {
    try {
      // First, check if location services are enabled on the device.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services are disabled.', name: _logName);
        throw Exception('Location services are disabled.');
      }

      // Permissions are handled by the caller (WeatherDataState).
      // We directly try to get the current position.
      return await Geolocator.getCurrentPosition();
      
    } catch (e) {
      // If ANY error occurs (permission denied, timeout, GPS off, etc.)
      log('Failed to get real location: $e. Returning default location.', name: _logName);
      // Return a default position (Taipei City Hall)
      return Position(
        latitude: 25.0375, 
        longitude: 121.5647, 
        timestamp: DateTime.now(), 
        accuracy: 0.0, 
        altitude: 0.0, 
        altitudeAccuracy: 0.0, 
        heading: 0.0, 
        headingAccuracy: 0.0, 
        speed: 0.0, 
        speedAccuracy: 0.0
      );
    }
  }

  Future<String?> getAdministrativeDivision(double latitude, double longitude) async {
    final String url = 'https://api.nlsc.gov.tw/other/TownVillagePointQuery1/$longitude/$latitude/4326';
    log('Requesting administrative division from URL: $url', name: _logName);

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final xmlString = utf8.decode(response.bodyBytes);
        
        // Handle empty response from API for out-of-bounds coordinates
        if (xmlString.trim().isEmpty) {
          log('API returned an empty response, likely out of Taiwan bounds.', name: _logName);
          return null;
        }

        log('API Response Body (Success, UTF-8 decoded): $xmlString', name: _logName);
        final document = XmlDocument.parse(xmlString);

        final townVillageItem = document.findAllElements('townVillageItem').first;
        final ctyName = townVillageItem.findElements('ctyName').first.text;
        final townName = townVillageItem.findElements('townName').first.text;

        return '$ctyName $townName';
      } else {
        log('Failed to load administrative division: ${response.statusCode}', name: _logName);
        log('API Response Body (Error Status): ${response.body}', name: _logName);
        return null;
      }
    } catch (e) {
      log('Error fetching administrative division: $e', name: _logName);
      if (e is http.ClientException && e.message.contains('Failed to fetch')) {
         log('ClientException on web, response body not directly available in error.', name: _logName);
      } else if (e.toString().contains('XmlParserException')) {
         log('XmlParserException occurred. Check the preceding logs for the response body.', name: _logName);
      } else {
         log('Unexpected error type, could not log response body from exception.', name: _logName);
      }
      return null;
    }
  }
}
