import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_alert.dart';

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
          try {
            final authorName = entry['author']?['name'] as String?;
            final title = entry['title'] as String?;

            if (authorName == null || title == null) continue;

            bool shouldAdd = false;
            if (authorName == '中央氣象署') {
              shouldAdd = true;
            } else if (authorName == '水利署' && title == '淹水') {
              shouldAdd = true;
            }

            if (shouldAdd) {
              alerts.add(WeatherAlert.fromJson(entry));
            }
          } catch (e) {
            log('Error parsing or filtering alert entry: $e');
          }
        }
        return alerts;
      } else {
        // Handle non-200 status code
        log('Failed to load alerts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Handle network or other errors
      log('Error fetching alerts: $e');
      return [];
    }
  }
}
