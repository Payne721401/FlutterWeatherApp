import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class AlertService {
  final String apiUrl = 'https://alerts.ncdr.nat.gov.tw/JSONAtomFeeds.ashx';

  Future<List<WeatherAlert>> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> entries = data['entry'] ?? [];

        List<WeatherAlert> alerts = [];
        for (var entry in entries) {
          // Check if author is 中央氣象署 or 水利署
          if (entry['author'] != null &&
              entry['author']['name'] != null &&
              (entry['author']['name'] == '中央氣象署' || entry['author']['name'] == '水利署')) {
            try {
              alerts.add(WeatherAlert.fromJson(entry));
            } catch (e) {
              print('Error parsing alert entry: $e');
              // Continue to the next entry if parsing fails for one
            }
          }
        }
        return alerts;
      } else {
        // Handle non-200 status code
        print('Failed to load alerts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Handle network or other errors
      print('Error fetching alerts: $e');
      return [];
    }
  }
}