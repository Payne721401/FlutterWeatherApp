import 'dart:convert';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  // Helper method to create a copy with modified fields
  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // Methods for JSON serialization/deserialization for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Announcement.fromJson(String source) =>
      Announcement.fromMap(json.decode(source));
}
