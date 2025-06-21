import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart'; // For XML parsing
import 'package:geolocator/geolocator.dart'; // Assuming used for getCurrentLocation
import 'dart:developer'; // Import for log

// You might need to handle location permissions before calling getCurrentLocation.
// Example using geolocator:
// Future<Position> _determinePosition() async {
//   bool serviceEnabled;
//   LocationPermission permission;

//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     return Future.error('Location services are disabled.');
//   }

//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       return Future.error('Location permissions are denied');
//     }
//   }

//   if (permission == LocationPermission.deniedForever) {
//     return Future.error(
//         'Location permissions are permanently denied, we cannot request permissions.');
//   }

//   return await Geolocator.getCurrentPosition();
// }

class LocationService {
  static const String _logName = 'LocationService'; // Define a log name

  // Placeholder for getting current location (replace with actual geolocator implementation)
  Future<Position> getCurrentLocation() async {
    // In a real app, use geolocator.getCurrentPosition();
    // For now, returning a fixed location for demonstration/testing
    // This fixed location is for Taipei 101 for testing administrative division lookup
    log('Using fixed location for demonstration.', name: _logName);
    return Position(latitude: 25.0338, longitude: 121.5646, timestamp: DateTime.now(), accuracy: 0.0, altitude: 0.0, altitudeAccuracy: 0.0, heading: 0.0, headingAccuracy: 0.0, speed: 0.0, speedAccuracy: 0.0);
    // If you want to test the error handling, uncomment the line below
    // throw Exception('Failed to get current location (simulated error)');
  }

  // Get administrative division (county/township) from latitude and longitude
  Future<String?> getAdministrativeDivision(double latitude, double longitude) async {
    final String url = 'https://api.nlsc.gov.tw/other/TownVillagePointQuery1/$longitude/$latitude/4326';
    log('Requesting administrative division from URL: $url', name: _logName); // Use log

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Decode response body as UTF-8 explicitly
        final xmlString = utf8.decode(response.bodyBytes);
        log('API Response Body (Success, UTF-8 decoded): $xmlString', name: _logName); // Use log
        final document = XmlDocument.parse(xmlString);

        final townVillageItem = document.findAllElements('townVillageItem').first;
        final ctyName = townVillageItem.findElements('ctyName').first.text;
        final townName = townVillageItem.findElements('townName').first.text;

        return '$ctyName $townName';
      } else {
        log('Failed to load administrative division: ${response.statusCode}', name: _logName);
        log('API Response Body (Error Status): ${response.body}', name: _logName); // Use log
        return null;
      }
    } catch (e) {
      log('Error fetching administrative division: $e', name: _logName); // Use log for error
      // Attempt to log the response body if available in the caught exception (might not be standard)
      if (e is http.ClientException && e.message.contains('Failed to fetch')) {
         // This specific ClientException on web might not have a response body accessible here
         log('ClientException on web, response body not directly available in error.', name: _logName);
      } else if (e.toString().contains('XmlParserException')) {
         // For XmlParserException, the problematic body content is what we need.
         // Unfortunately, the exception itself doesn't usually contain the body.
         // We need to rely on the log on success or error status above.
         log('XmlParserException occurred. Check the preceding logs for the response body.', name: _logName);
      } else {
         log('Unexpected error type, could not log response body from exception.', name: _logName);
      }
      return null;
    }
  }
}
