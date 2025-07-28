// Represents a weather alert, now in its own file.
class WeatherAlert {
  final String title;
  final String description;
  final DateTime issuedTime;
  final String authorName;

  WeatherAlert({
    required this.title,
    required this.description,
    required this.issuedTime,
    required this.authorName,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      title: json['title'] as String? ?? 'No Title',
      description: (json['summary'] as Map<String, dynamic>?)?['#text'] as String? ?? 'No Description',
      issuedTime: DateTime.tryParse(json['updated'] as String? ?? '') ?? DateTime.now(),
      authorName: (json['author'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown Author',
    );
  }
}
