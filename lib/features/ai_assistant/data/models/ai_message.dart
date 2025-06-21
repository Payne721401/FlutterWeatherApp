import 'package:flutter/material.dart';

class MessageData {
  MessageData({this.image, this.text, this.fromUser, this.suggestions, this.isTyping = false, this.weatherReportData});
  final Image? image;
  final String? text;
  final bool? fromUser;
  final List<AISuggestion>? suggestions;
  final bool isTyping; // New property for typing animation
  final Map<String, dynamic>? weatherReportData; // New property for structured weather data
}

class AISuggestion {
  final String title;
  final String description;

  AISuggestion({required this.title, required this.description});

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      title: json['title'] ?? 'Suggestion',
      description: json['description'] ?? 'Details about the suggestion.',
    );
  }
}
